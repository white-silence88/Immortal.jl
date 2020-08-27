module Consumers
    include("../../utils/Utils.jl")
    import .Utils

    using AMQPClient

    export base_consumer

    """ Функция базового консьюмера для подписки на очередь.


    channel: канал связи с сервисом очередей, 
    message: сообщение от сервиса очередей, 
    user_consumer_reaction: функция пользовательской реакции
    """
    function  base_consumer(channel::AMQPClient.MessageChannel, message::AMQPClient.Message, user_consumer_reaction::Function)::Bool
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ " channel
        @debug "> сообщение из очереди " message
        @debug "> функция консьюмера пользователя " user_consumer_reaction
        try
            @debug "Запускается пользовательская операция обработки реакции " user_consumer_reaction
            user_consumer_reaction(message)
            AMQPClient.basic_ack(channel, message.delivery_tag)
            return true
        catch error
            @error Utils.Chronometer.message_with_time("Не удалось отреагировать") error
            throw(error)
        end
    end
end