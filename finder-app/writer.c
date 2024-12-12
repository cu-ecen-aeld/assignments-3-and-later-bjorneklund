#include <stdlib.h>
#include <stdio.h>
#include <syslog.h>
#include <errno.h>
#include <string.h>

int main(int argc, const char* argv[])
{
    //Open syslog
    openlog("Writer-App", LOG_ODELAY, LOG_USER);

    if ( argc < 2)
    {
        syslog(LOG_ERR, "Syntax: <file> <message>");
        exit(EXIT_FAILURE);
    }

    if ( argc < 3 )
    {
        syslog(LOG_ERR, "No message provided");
        exit(EXIT_FAILURE);
    }

    const char * message = argv[2];
    const char * filename = argv[1];

    FILE * file = fopen(filename, "w+");
    if ( file == NULL )
    {
        int error_code = errno;
        syslog(LOG_ERR, "Could not open %s for writing due to %s", filename, strerror(error_code));
        exit(EXIT_FAILURE);
    }

    syslog(LOG_DEBUG, "Writing %s to %s", message, filename);
    size_t message_length = strlen(message);
    fwrite(message, sizeof(char), message_length, file);
        
    if ( errno != 0 )
    {
        int error_code = errno;
        syslog(LOG_ERR, "Could not write to %s due to %s", filename, strerror(error_code));
    }

    fclose(file);

    if ( errno != 0 )
    {
        int error_code = errno;
        syslog(LOG_ERR, "Could not close %s due to %s", filename, strerror(error_code));
    }
    
    closelog();
    return EXIT_SUCCESS;
}