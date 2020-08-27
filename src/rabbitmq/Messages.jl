module Messages
    include("../Chronometer.jl")
    import .Chronometer

    using AMQPClient

    export create_and_publish

    """Функция создания сообщения с его последующей публикацией.


    channel: канал связи с сервисом очередей,
    exchanger: имя обменника,
    route: имя маршрута,
    data: данные, которые требуется передать в сообщении,
    props: настройки для передаваемого сообщения
    """
    function create_and_publish(channel::AMQPClient.MessageChannel, exchanger::String, route::String, data::Any, props::Dict{String, Any})::Bool
        try
            data_to_send = Vector{UInt8}(data)
            message::AMQPClient.Message = AMQPClient.Message(
                data_to_send,
                content_type= get(props, "CONTENT_TYPE", nothing),
                content_encoding = get(props, "CONTENT_ENCODING", nothing),
                headers = get(props, "HEADERS", nothing),
                delivery_mode = get(props, "DELIVERY_MODE", nothing),
                priority = get(props, "PRIORITY", 0),
                correlation_id = get(props, "CORRELATION_ID", nothing),
                reply_to = get(props, "REPLY_TO", nothing),
                expiration = get(props, "EXPIRATION", nothing),
                message_id = get(props, "MESSAGE_ID", nothing),
                timestamp = get(props, "TIMESTAMP", nothing),
                message_type = get(props, "MESSAGE_TYPE", nothing),
                user_id = get(props, "USER_ID", nothing),
                app_id = get(props, "APPLICATION_ID", nothing)
            )
            AMQPClient.basic_publish(channel, message; exchange=exchanger, routing_key=route)
            return true
        catch error
            @error Chronometer.message_with_time("Создание и отправка сообщения завершилось ошибой") error
            throw(error)
        end
    end

end
