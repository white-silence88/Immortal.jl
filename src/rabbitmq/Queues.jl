module Queues
    include("Consumers.jl")
    import .Consumers

    include("../Chronometer.jl")
    import .Chronometer

    using AMQPClient

    export delete, declare, bind, unbind, purge, unsubscribe, subscribe

    """Функция подписки на сообщения очереди.


    channel: канал связи с сервисом очередей
    queue_name: имя очереди в сервисе очередей
    user_consumer_reaction: пользовательская функция консьюмера
    """
    function subscribe(channel::AMQPClient.MessageChannel, queue_name::String, user_consumer_reaction::Function)::Bool
        @info Chronometer.message_with_time("Вызвана операция подписки на очередь $queue_name")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ " channel
        @debug "> имя очереди " queue_name
        @debug "> функция консьюмера пользователя " user_consumer_reaction
        try
            consumer(message) = Consumers.base_consumer(channel, message, user_consumer_reaction)
            @debug "Итоговый консьюмер " consumer
            success, consumer_tag = AMQPClient.basic_consume(channel, queue_name, consumer)
            @debug "Результат выполненя подписки " success
            @debug "Тег консьюмера " consumer_tag
            @assert success
            @info Chronometer.message_with_time("Зарегистрирован консьюмер с тегом $consumer_tag")
            return success
        catch error
            @error Chronometer.message_with_time("Не удалось подписаться на сообщения очереди ") error
        end
    end

    """ Функция, которая позволяет отписаться от прослушивания очереди.


    channel: канал связи с сервисом очередей, 
    consume_tag: тег консьюмера
    """
    function unsubscribe(channel::AMQPClient.MessageChannel, consume_tag::String)::Bool
        @info Chronometer.message_with_time("Вызвана функция отписки консьюмера от очереди")
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ " channel
        @debug "> тег консьюмера " consume_tag
        try
            return AMQPClient.basic_cancel(channel, consume_tag)
        catch error
            @error Chronometer.message_with_time("Не удалось отписаться от очереди, возникла ошибка ") error
            throw(error)
        end
    end

    """Функция очистки очереди.


    channel: канал связи с сервисом очередей, 
    queue_name: имя очереди
    """
    function purge(channel::AMQPClient.MessageChannel, queue_name::String)::Dict{String, Any}
        # Вызываем функция логирования
        @info Chronometer.message_with_time("Вызвана функция очистки очериди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> имя очереди" queue_name
        # Пробуем очистить очередь в канале по имени
        try
            # Если очередь очистится получим два значения - результат и
            # количество сообщений
            result, message_count = AMQPClient.queue_purge(channel, queue_name)
            # Дополняем логирование для режима отладки
            @debug ">> результат выполнения операции очистки очереди" result
            @debug ">> количество сообщений в очереди" message_count
            # вычисляем сообщение для логирования уровня info и выводим его
            message::String = result ? "Очередь успешно очищена" : "Не удалось совершить очистку очереди"
            @info string("=> ", message)
            # Возвращаем словарь с результатами работы функци, содержащий ключи:
            # STATUS - результат выполнения операции очистки очереди
            # QUEUE - наименование очереди
            # MSG_COUNT - количество сообщений
            return Dict{String, Any}(
                "STATUS" => result,
                "QUEUE" => queue_name,
                "MSG_COUNT" => message_count
            )
        catch error
            # Обрабатываем исключение. Выводим его в терминал и кидаем ошибку
            @error Chronometer.message_with_time("Очистка очереди завершилась с ошибкой ") error
            throw(error)
        end
    end

    """Функция, которая позволяет отвязать очередь от маршрута.


    channel: канал связи с сервисом очередей, 
    queue_name: имя очереди, 
    exchanger_name: имя обменника,
    route_name: имя маршрута
    """
    function unbind(channel::AMQPClient.MessageChannel, queue_name::String, exchanger_name::String, route_name)::Bool
        # Вызываем функця логирования
        @info Chronometer.message_with_time("Вызвана функция отвызывания от очереди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> имя очереди" queue_name
        @debug "> имя обменника" exchanger_name
        @debug "> имя маршрута" route_name
        # Пытаемся отвязать маршрут от череди
        try
            # Получаем результат отвязывания маршрута от очереди
            result = AMQPClient.queue_unbind(channel, queue_name, exchanger_name, route_name)
            # Дополняем логи для уровня отладки
            @debug ">> результат отвязывания очереди, обменника и маршрута" result
            # Собираем сообщение из результат
            message::String = result ? "Отвязывание от очереди и обменника прошло успешно" : "Не удалось совершить отвязывание"
            @info string("=> ", message)
            # Возвращаем результат выполнения операции отвязывания
            return result
        catch error
            # Обрабатываем ошибку: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Возникла ошибка при отвязывание")
            throw(error)
        end
    end

    """Функция связывание очереди и маршрута.


    channel: канал связи с сервисом очередей, 
    queue_name: имя очереди,
    exchanger_name: имя обменнника, 
    route_name: имя маршрута
    """
    function bind(channel::AMQPClient.MessageChannel, queue_name::Any, exchanger_name::Any, route_name::String)::Dict{String, Any}
        # Выводим информационное сообщение в логер
        @info Chronometer.message_with_time("Вызвана функция связывания с очередью")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> имя очереди" queue_name
        @debug "> имя обменника" exchanger_name
        @debug "> имя маршрута" route_name
        # Пытаемся связать очередь, обменник и маршрут в канале
        try
            # Запускаем операцию связывания. Её реультат всегда типа Bool
            result::Bool = AMQPClient.queue_bind(channel, queue_name, exchanger_name, route_name)
            # Дополняем логирование для режима отладки. Выводим результат операции
            @debug ">> результат связывания очереди, обменника и маршрута" result
            # Вычисляем какое сообщение показывать в информационных логах
            message::String = result ? "Связывание очереди и обменника прошло успешно" : "Не удалось совершить связывание"
            @info string("=> ", message)
            # Возвращаем результат работы функции.
            # В качестве возвращаемого значеня используем словарь (маршрут),
            # в котором содержатся следующие ключи:
            # NAME - наименование роута
            # QUEUE - имя очереди
            # ECHANGE - имя обменника
            return Dict{String, Any}(
                "NAME" => route_name,
                "QUEUE" => queue_name,
                "EXCHANGE" => exchanger_name
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Возникла ошибка при связывании")
            throw(error)
        end
    end

    """Функция регистрации очереди.


    channel: канал связи с сервисом очередей
    queue_id: идетификатор очереди
    """
    function declare(channel::AMQPClient.MessageChannel, queue_id::String)::Dict{String, Any}
        # Выводим информационное сообщение в терминал
        @info Chronometer.message_with_time("Вызвана функция регистрации очереди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> идетификатор очереди" queue_id
        # Пытаемся объявить очередь
        try
            # Вызываем функцию объявления очереди. В качестве результата
            # возвращаются значения
            # result - результат выполнеиня операции
            # queue_name - имя очереди
            # message_count - количество сообщений
            # consumer_count - количество потребителей
            result, queue_name, message_count, consumer_count = AMQPClient.queue_declare(channel, queue_id)
            # Дополняем логирование для режима отладки
            @debug ">> результат операции объявления очереди" result
            @debug ">> имя очереди" queue_name
            @debug ">> количество сообщений в очереди" message_count
            @debug ">> число слушателей/потребителей" consumer_count
            # Исходя из результата вычисляем сообщение для информационного лога
            message::String = result ? "Очередь зарегистрирована удачно" : "Не удалось зарегистрировать очередь"
            @info string("=> ", message)
            # Возвращаем результат (словарь), который содержит ключи
            # STATUS - результат выполнения операции объявления
            # NAME - наименование очереди
            # MSG_COUNT - количество сообщений
            # CONS_COUNT - количество потребителей
            return Dict{String, Any}(
                "STATUS" => result,
                "NAME" => queue_name,
                "MSG_COUNT" => message_count,
                "CONS_COUNT" => consumer_count
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Регистрация очереди завершилась ошибкой ") error
            throw(error)
        end
    end

    """Функция удаления очереди.


    channel: канал связи с сервисом очередей
    queue_id: идетификатор очереди
    """
    function delete(channel::AMQPClient.MessageChannel, queue_id::Any)::Dict{String, Any}
        # Выводим информационное сообщение
        @info Chronometer.message_with_time("Запущена функуция удаления очереди...")
        # Логирование для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> идетификатор очереди" queue_id
        #
        try
            # Выполняем функцию удаления очереди, возвращается два результата
            # result - результат операции удаления
            # message_count - количество сообщений в очереди
            result, message_count = queue_delete(channel, queue_id)
            # Дополняем логирование в режиме отладки. Выводим результаты
            @debug ">> результат выполненя операции удаления очереди" result
            @debug ">> количество сообщений в очереди" message_count
            # Собираем сообщение в заивисимости от результата
            message::String = result ? "Удаление очереди прошло успешно" : "Не удалось удалить очередь"
            @info string("=> ", message)
            # Возвращаем словарь с результатами, содержащий поля:
            # STATUS - статус выполнения операции
            # MSG_COUNT - количество сообщений
            return Dict{String, Any}(
                "STATUS" => result,
                "MSG_COUNT" => message_count
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Удаление очереди завершилось ошибкой ") error
            throw(error)
        end
    end
end
