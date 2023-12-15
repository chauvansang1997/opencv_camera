#include <string>
void platform_log(const char *fmt, ...);

//curl reponse to dart side
struct CurlResponse{
    const char* data;
    int status;
};

//read file data to dart side convert to Uint8List
struct FileData{
    uint8_t* bytes;
    int length;
};

//curl form data use with [curl_post_form_data]
struct CurlFormData{
    std::string name;
    std::string value;
    int type;
};