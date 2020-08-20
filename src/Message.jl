module Message
    include("Chronometer.jl")
    import .Chronometer

    using AMQPClient

    export create

    """
        Функция создания собощения для сервера RabbitMQ
    """
    function create(data::Any)::AMQPClient.Message
        data_to_send = Vector{UInt8}(data)
        try
            result = AMQPClient.Message(data_to_send)
            return result
        catch error
            @error "Создание сообщения завершилось ошибкой" error
            throw(error)
        end
        return result
    end
end
