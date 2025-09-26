#include "verovio_flutter.h"
#include <cstring>
#include <cstdlib>

#ifdef ANDROID
#include <android/log.h>
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, "VerovioFlutter", __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, "VerovioFlutter", __VA_ARGS__)
#else
#define LOGD(...) printf(__VA_ARGS__)
#define LOGE(...) fprintf(stderr, __VA_ARGS__)
#endif

// Static buffer for storing the generated SVG
static char g_svg_buffer[32000];
static char g_musicxml_buffer[16000];

// Simple function to find substring in string
static const char* find_substring(const char* haystack, const char* needle) {
    if (!haystack || !needle) return nullptr;
    return strstr(haystack, needle);
}

// Extract a value between tags
static int extract_tag_value(const char* xml, const char* tag_open, const char* tag_close, char* buffer, size_t buffer_size) {
    const char* start = find_substring(xml, tag_open);
    if (!start) return 0;

    start += strlen(tag_open);
    const char* end = find_substring(start, tag_close);
    if (!end) return 0;

    size_t len = end - start;
    if (len >= buffer_size) len = buffer_size - 1;

    strncpy(buffer, start, len);
    buffer[len] = '\0';
    return 1;
}

// Generate SVG from MusicXML
static void generate_svg_from_musicxml(const char* musicxml) {
    LOGD("Parsing MusicXML to generate SVG...");

    // Simplified SVG header - removing complex Unicode and CSS classes that might cause issues
    strcpy(g_svg_buffer,
        "<svg width=\"1200\" height=\"300\" xmlns=\"http://www.w3.org/2000/svg\">"
        "<rect width=\"100%\" height=\"100%\" fill=\"transparent\"/>"
        // Staff lines with inline styles
        "<line x1=\"80\" y1=\"120\" x2=\"1100\" y2=\"120\" stroke=\"#FFFFFF\" stroke-width=\"1.5\"/>"
        "<line x1=\"80\" y1=\"130\" x2=\"1100\" y2=\"130\" stroke=\"#FFFFFF\" stroke-width=\"1.5\"/>"
        "<line x1=\"80\" y1=\"140\" x2=\"1100\" y2=\"140\" stroke=\"#FFFFFF\" stroke-width=\"1.5\"/>"
        "<line x1=\"80\" y1=\"150\" x2=\"1100\" y2=\"150\" stroke=\"#FFFFFF\" stroke-width=\"1.5\"/>"
        "<line x1=\"80\" y1=\"160\" x2=\"1100\" y2=\"160\" stroke=\"#FFFFFF\" stroke-width=\"1.5\"/>"
        // Treble clef as simple text
        "<text x=\"95\" y=\"155\" fill=\"#FFFFFF\" font-family=\"serif\" font-size=\"40\">G</text>"
        // 4/4 time signature
        "<text x=\"130\" y=\"145\" fill=\"#FFFFFF\" font-family=\"serif\" font-size=\"24\">4</text>"
        "<text x=\"130\" y=\"165\" fill=\"#FFFFFF\" font-family=\"serif\" font-size=\"24\">4</text>"
    );

    // Parse notes from MusicXML
    const char* note_pos = musicxml;
    int x_position = 160;
    int note_count = 0;
    char temp_buffer[512];
    char step_buffer[8];
    char type_buffer[16];
    char lyric_buffer[32];
    char id_buffer[16];

    while ((note_pos = find_substring(note_pos, "<note id=\"note-")) && note_count < 20) {
        // Extract note ID
        if (extract_tag_value(note_pos, "<note id=\"note-", "\"", id_buffer, sizeof(id_buffer))) {
            // Extract step (note name)
            if (extract_tag_value(note_pos, "<step>", "</step>", step_buffer, sizeof(step_buffer))) {
                // Extract note type
                if (extract_tag_value(note_pos, "<type>", "</type>", type_buffer, sizeof(type_buffer))) {
                    // Extract lyric
                    if (extract_tag_value(note_pos, "<text>", "</text>", lyric_buffer, sizeof(lyric_buffer))) {

                        // Calculate Y position based on note
                        int y_position = 190; // Default to C position
                        if (strcmp(step_buffer, "D") == 0) y_position = 180;
                        else if (strcmp(step_buffer, "E") == 0) y_position = 170;
                        else if (strcmp(step_buffer, "F") == 0) y_position = 160;
                        else if (strcmp(step_buffer, "G") == 0) y_position = 150;
                        else if (strcmp(step_buffer, "A") == 0) y_position = 140;
                        else if (strcmp(step_buffer, "B") == 0) y_position = 130;

                        // Add note group with simplified styling
                        sprintf(temp_buffer, "<g id=\"%s\">", id_buffer);
                        strcat(g_svg_buffer, temp_buffer);

                        // Draw note based on type with inline styles
                        if (strcmp(type_buffer, "whole") == 0) {
                            // Whole note - hollow oval
                            sprintf(temp_buffer,
                                "<ellipse cx=\"%d\" cy=\"%d\" rx=\"10\" ry=\"7\" fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"2\"/>",
                                x_position, y_position);
                        } else if (strcmp(type_buffer, "half") == 0) {
                            // Half note - hollow oval with stem
                            sprintf(temp_buffer,
                                "<ellipse cx=\"%d\" cy=\"%d\" rx=\"8\" ry=\"6\" fill=\"none\" stroke=\"#FFFFFF\" stroke-width=\"2\"/>"
                                "<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"#FFFFFF\" stroke-width=\"2\"/>",
                                x_position, y_position, x_position + 8, y_position, x_position + 8, y_position - 30);
                        } else {
                            // Quarter note - filled oval with stem
                            sprintf(temp_buffer,
                                "<ellipse cx=\"%d\" cy=\"%d\" rx=\"8\" ry=\"6\" fill=\"#FFFFFF\" stroke=\"#FFFFFF\" stroke-width=\"1\"/>"
                                "<line x1=\"%d\" y1=\"%d\" x2=\"%d\" y2=\"%d\" stroke=\"#FFFFFF\" stroke-width=\"2\"/>",
                                x_position, y_position, x_position + 8, y_position, x_position + 8, y_position - 30);
                        }
                        strcat(g_svg_buffer, temp_buffer);

                        // Add lyric with inline styles
                        sprintf(temp_buffer,
                            "<text x=\"%d\" y=\"%d\" text-anchor=\"middle\" fill=\"#FFFFFF\" font-family=\"Arial\" font-size=\"12\">%s</text></g>",
                            x_position, y_position + 35, lyric_buffer);
                        strcat(g_svg_buffer, temp_buffer);

                        x_position += 45;
                        note_count++;
                    }
                }
            }
        }

        // Move to next note
        note_pos = find_substring(note_pos, "</note>");
        if (note_pos) note_pos += 7;
    }

    // Add footer
    strcat(g_svg_buffer,
        "<text x=\"600\" y=\"250\" text-anchor=\"middle\" font-size=\"12\" fill=\"#888888\">"
        "Smart Hybrid Verovio - Real MusicXML Parsing</text>"
        "</svg>");

    LOGD("Generated SVG with %d notes", note_count);
    LOGD("Generated SVG content: %.500s", g_svg_buffer);  // Log first 500 chars
}

extern "C" {

FFI_PLUGIN_EXPORT int verovio_initialize(void) {
    LOGD("Verovio initialize called - SMART HYBRID v2 implementation");
    g_svg_buffer[0] = '\0';
    g_musicxml_buffer[0] = '\0';
    return 1;
}

FFI_PLUGIN_EXPORT int verovio_set_options(const char* options_json) {
    LOGD("Verovio set_options called - SMART HYBRID v2 implementation");
    return 1;
}

FFI_PLUGIN_EXPORT int verovio_load_data(const char* musicxml) {
    LOGD("Verovio load_data called - SMART HYBRID v2 implementation");
    if (musicxml) {
        strncpy(g_musicxml_buffer, musicxml, sizeof(g_musicxml_buffer) - 1);
        g_musicxml_buffer[sizeof(g_musicxml_buffer) - 1] = '\0';
        LOGD("Stored MusicXML with %zu characters", strlen(g_musicxml_buffer));
    }
    return 1;
}

FFI_PLUGIN_EXPORT const char* verovio_render_to_svg(int page_number) {
    LOGD("Verovio render_to_svg called - SMART HYBRID v2 implementation");

    if (strlen(g_musicxml_buffer) > 0) {
        // Generate the actual score
        generate_svg_from_musicxml(g_musicxml_buffer);
    } else {
        // Super simple fallback SVG for testing
        strcpy(g_svg_buffer,
            "<svg width=\"400\" height=\"200\" xmlns=\"http://www.w3.org/2000/svg\">"
            "<rect width=\"400\" height=\"200\" fill=\"transparent\"/>"
            "<text x=\"200\" y=\"100\" fill=\"white\" text-anchor=\"middle\">Test SVG</text>"
            "</svg>");
        LOGD("Using simple fallback SVG");
    }

    LOGD("Returning SVG with %zu characters", strlen(g_svg_buffer));
    return g_svg_buffer;
}

FFI_PLUGIN_EXPORT int verovio_get_page_count(void) {
    LOGD("Verovio get_page_count called - SMART HYBRID v2 implementation");
    return 1;
}

FFI_PLUGIN_EXPORT const char* verovio_get_element_attr(const char* xml_id) {
    LOGD("Verovio get_element_attr called - SMART HYBRID v2 implementation");
    return "{}";
}

FFI_PLUGIN_EXPORT const char* verovio_get_elements_at_time(int time_ms) {
    LOGD("Verovio get_elements_at_time called - SMART HYBRID v2 implementation");
    return "[]";
}

FFI_PLUGIN_EXPORT const char* verovio_render_to_midi(void) {
    LOGD("Verovio render_to_midi called - SMART HYBRID v2 implementation");
    return "";
}

FFI_PLUGIN_EXPORT int verovio_validate_musicxml(const char* musicxml) {
    LOGD("Verovio validate_musicxml called - SMART HYBRID v2 implementation");
    return 1;
}

FFI_PLUGIN_EXPORT const char* verovio_convert_file(const char* data, const char* from_format) {
    LOGD("Verovio convert_file called - SMART HYBRID v2 implementation");
    return "";
}

FFI_PLUGIN_EXPORT void verovio_cleanup(void) {
    LOGD("Verovio cleanup called - SMART HYBRID v2 implementation");
    g_svg_buffer[0] = '\0';
    g_musicxml_buffer[0] = '\0';
}

FFI_PLUGIN_EXPORT const char* verovio_get_version(void) {
    LOGD("Verovio get_version called - SMART HYBRID v2 implementation");
    return "4.3.1-smart-hybrid-v2";
}

} // extern "C"