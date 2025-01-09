#include "systemcalls.h"

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
*/
bool do_system(const char *cmd)
{

/*
 * TODO  add your code here
 *  Call the system() function with the command set in the cmd
 *   and return a boolean true if the system() call completed with success
 *   or false() if it returned a failure
*/
    int status = system(cmd);
    return status == 0;
}

/**
* @param count -The numbers of variables passed to the function. The variables are command to execute.
*   followed by arguments to pass to the command
*   Since exec() does not perform path expansion, the command to execute needs
*   to be an absolute path.
* @param ... - A list of 1 or more arguments after the @param count argument.
*   The first is always the full path to the command to execute with execv()
*   The remaining arguments are a list of arguments to pass to the command in execv()
* @return true if the command @param ... with arguments @param arguments were executed successfully
*   using the execv() call, false if an error occurred, either in invocation of the
*   fork, waitpid, or execv() command, or if a non-zero return value was returned
*   by the command issued in @param arguments with the specified arguments.
*/

bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
        //printf("Command %d: %s\n", i, command[i]);
    }
    command[count] = NULL;

/*
 * TODO:
 *   Execute a system command by calling fork, execv(),
 *   and wait instead of system (see LSP page 161).
 *   Use the command[0] as the full path to the command to execute
 *   (first argument to execv), and use the remaining arguments
 *   as second argument to the execv() command.
 *
*/
    int status = -1;
    pid_t child_pid = fork();
    if ( child_pid == -1 )
    {
        int error_code = errno;
        fprintf(stderr, "Could not create child, (%d), %s\n", error_code, strerror(error_code));
        exit(1);
    }

    if ( child_pid == 0 )
    {
        //Child process
        int return_code = execv(command[0], command );
        if ( return_code != 0 )
        {
            exit(2);
        }
    }
    else
    {
        //parent wait for child process
        waitpid(child_pid, &status, 0);
        if ( WIFEXITED(status))
        {
            status = WEXITSTATUS(status);  
            //fprintf(stdout, "Child exited with status- code %d\n", status);
        }
    }

    va_end(args);

    return status == 0;
}

/**
* @param outputfile - The full path to the file to write with command output.
*   This file will be closed at completion of the function call.
* All other parameters, see do_exec above
*/
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char * command[count+1];
    int i;
    for(i=0; i<count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;


/*
 * TODO
 *   Call execv, but first using https://stackoverflow.com/a/13784315/1446624 as a refernce,
 *   redirect standard out to a file specified by outputfile.
 *   The rest of the behaviour is same as do_exec()
 *
*/

    int fd = open(outputfile, O_WRONLY | O_TRUNC | O_CREAT, 0644);
    if ( fd == -1 )
    {
        int error_code = errno;
        fprintf(stderr, "Could not open/create file, (%d), %s\n", error_code, strerror(error_code));
        exit(1);
    }

    int status = 0;
    pid_t child_pid = fork();
    if ( child_pid == -1 )
    {
        int error_code = errno;
        fprintf(stderr, "Could not create child, (%d), %s\n", error_code, strerror(error_code));
        close(fd);
        exit(2);
    }

    if ( child_pid == 0 )
    {
        //Child process

        //duplicate the parent filedescriptor to child stdout (fd = 1)
        if ( dup2(fd, 1) < 0 ) 
        { 
            int error_code = errno;
            fprintf(stderr, "Could not redirect std- output to file, (%d), %s", error_code, strerror(error_code));
            exit(3);
        }

        int return_code = close(fd);
        if ( return_code == -1 )
        {
            int error_code = errno;
            fprintf(stderr, "Child: Could not close file, (%d), %s\n", errno, strerror(error_code));
            exit(4);
        }

        return_code = execv(command[0], command );
        if ( return_code != 0 )
        {
            exit(5);
        }
    }
    else
    {
        //parent wait for child process
        waitpid(child_pid, &status, 0);
        if ( WIFEXITED(status))
        {
            status = WEXITSTATUS(status);  
            //fprintf(stdout, "Child exited with status- code %d\n", status);
        }
    
        int return_code = close(fd);

        if ( return_code == -1 )
        {
            int error_code = errno;
            fprintf(stderr, "Parent: Could not close file, (%d), %s\n", errno, strerror(error_code));
            exit(4);
        }
    }

   
    va_end(args);

    return status == 0;
}
