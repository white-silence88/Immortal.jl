module Immortal
    include("Rabbit.jl")
    import .Rabbit


    """
        Функция для запуска сервера для работы с Rabbit
    """
    function run(login::String, password::String, vhost::String, port::Int64)
        host::String = "api.seon.cloud"
        is_connected::Bool = false
        connection = nothing

        try
            auth_params::Dict = Rabbit.get_auth_params(login, password)
            connection = Rabbit.get_rabbitmq_connection(vhost, host, port, auth_params)
            chanel = Rabbit.get_chanel(connection, nothing, true)
            is_connected = true
        catch e
            print(e)
        end

        Rabbit.shotdown(connection)
    end
end
