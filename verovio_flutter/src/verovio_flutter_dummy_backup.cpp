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

// Temporary implementation that returns dummy data to test basic FFI functionality
extern "C" {

FFI_PLUGIN_EXPORT int verovio_initialize(void) {
    LOGD("Verovio initialize called - DUMMY implementation");
    return 1; // Success
}

FFI_PLUGIN_EXPORT int verovio_set_options(const char* options_json) {
    LOGD("Verovio set_options called with: %s - DUMMY implementation", options_json ? options_json : "null");
    return 1; // Success
}

FFI_PLUGIN_EXPORT int verovio_load_data(const char* musicxml) {
    LOGD("Verovio load_data called - DUMMY implementation");
    return 1; // Success
}

FFI_PLUGIN_EXPORT const char* verovio_render_to_svg(int page_number) {
    LOGD("Verovio render_to_svg called for page %d - DUMMY implementation", page_number);
    // Return a simple SVG for testing
    static const char* dummy_svg =
        "<svg width=\"400\" height=\"200\" xmlns=\"http://www.w3.org/2000/svg\">"
        "<rect x=\"10\" y=\"10\" width=\"380\" height=\"180\" fill=\"white\" stroke=\"black\"/>"
        "<text x=\"200\" y=\"100\" text-anchor=\"middle\" font-size=\"16\">VEROVIO DUMMY SVG - SUCCESS!</text>"
        "</svg>";
    return dummy_svg;
}

FFI_PLUGIN_EXPORT int verovio_get_page_count(void) {
    LOGD("Verovio get_page_count called - DUMMY implementation");
    return 1; // Always return 1 page
}

FFI_PLUGIN_EXPORT const char* verovio_get_element_attr(const char* xml_id) {
    LOGD("Verovio get_element_attr called - DUMMY implementation");
    return "{}"; // Empty JSON
}

FFI_PLUGIN_EXPORT const char* verovio_get_elements_at_time(int time_ms) {
    LOGD("Verovio get_elements_at_time called - DUMMY implementation");
    return "[]"; // Empty array
}

FFI_PLUGIN_EXPORT const char* verovio_render_to_midi(void) {
    LOGD("Verovio render_to_midi called - DUMMY implementation");
    return ""; // Empty MIDI data
}

FFI_PLUGIN_EXPORT int verovio_validate_musicxml(const char* musicxml) {
    LOGD("Verovio validate_musicxml called - DUMMY implementation");
    return 1; // Always valid
}

FFI_PLUGIN_EXPORT const char* verovio_convert_file(const char* data, const char* from_format) {
    LOGD("Verovio convert_file called - DUMMY implementation");
    return ""; // Empty result
}

FFI_PLUGIN_EXPORT void verovio_cleanup(void) {
    LOGD("Verovio cleanup called - DUMMY implementation");
}

FFI_PLUGIN_EXPORT const char* verovio_get_version(void) {
    LOGD("Verovio get_version called - DUMMY implementation");
    return "4.3.1-dummy";
}

} // extern "C"