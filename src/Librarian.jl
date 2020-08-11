module Librarian
    # Add HTTP package for use in HTTP server
    using HTTP
    # Export functions from mudule
    ## Run server function fun run HTTP server
    export run_server

    """
        Function for run HTTP server.
    """
    function run_server()
        HTTP.serve() do request::HTTP.Request
            @show request
            @show request.method
            @show HTTP.header(request, "Content-Type")
            @show HTTP.payload(request)
            try
                return HTTP.Response("Hello")
            catch e
                return HTTP.Response(404, "Error: $e")
            end
        end
    end
end
