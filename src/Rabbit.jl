module Rabbit
    using AMQPClient
    export get_auth_params, get_rabbitmq_connection, get_chanel, shotdown


    """
        Функция закрывает соединение
    """
    function shotdown(conection)
        # Проверяем открыто ли соединение на данный момент
        if AMQPClient.isopen(conection)
            # Закрываем соединение
            AMQPClient.close(conection)
            # Закрытие соединеня асинхронная операция. Ждём завершения для всех каналов
            AMQPClient.wait_for_state(conection, AMQPClient.CONN_STATE_CLOSED)
        end
    end


    """
        Функция создания канала внутри коннекта к RabbitMQ
    """
    function get_chanel(connection, chanid, create)
        chanell_id = chanid == nothing ? AMQPClient.UNUSED_CHANNEL : chanid
        result = nothing
        try
            result = AMQPClient.channel(connection, chanell_id, create)
        catch error
            println("Not finded chanel")
        end
        return result
    end

    """
        Функция для получения параметров авторизации на RabbitMQ
    """
    function get_auth_params(login::String, password::String)
        mechanism::String = "AMQPLAIN"

        auth_params = Dict{String, Any}(
            "MECHANISM" => mechanism,
            "LOGIN" => login,
            "PASSWORD" => password
        )

        return auth_params
    end

    """
        Функция для получения коннекта на RabbitMQ
    """
    function get_rabbitmq_connection(vhost::String, host::String, port::Int64, auth_params::Dict)
        connection = AMQPClient.connection(
            ;virtualhost=vhost,
            host=host,
            port=port,
            auth_params=auth_params
        )

        return connection
    end
end
