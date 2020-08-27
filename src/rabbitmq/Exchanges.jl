module Exchanges
    # Подключаем библиотеку, связанную с временем
    include("../Chronometer.jl")
    import .Chronometer


    using AMQPClient

    export declare, delete

    """Функция удаления обменника.


    channel: канал связи с сервисом сообщений,
    exchange_id: идентификатор обменника
    """
    function delete(channel::AMQPClient.MessageChannel, exchange_id::String)::Bool
        # Выводим информационное сообщение
        @info Chronometer.message_with_time("Запущена функция удаления обменника...")
        # Логе для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с серверов RabbitMQ" channel
        @debug "> идентификатор обменника" exchange_id
        # Пытаемся удалить обменник
        try
            # Вызываем операцию удаления обменника по идентификатору
            result::Bool = AMQPClient.exchange_delete(channel, exchange_id)
            # Дополняем логирование для режима отладки
            @debug ">> результат операции удаления обменника" result
            # В зависимости от результат присваиваем заначение сообщени
            # для информационного уровня логирования и выводим его
            message::String = result ? "Обменник успешно удалён" : "Не удалось удалить обменник"
            @info string("=>", message)
            # Возвращаем результат выполения операции
            return result
        catch error
            #
            @error Chronometer.message_with_time("Удаление обменника завершилось ошибкой ") error
            throw(error)
        end
    end

    """Функция регистрации обменника.


    channel: сканал связи с сервисом сообщений,  
    exc_id: идентификатор обменника, 
    exc_type: тип обменника
    """
    function declare(channel::AMQPClient.MessageChannel, exc_id::String, exc_type::String)::Dict{String, Any}
        # Выводим информационное сообщение
        @info Chronometer.message_with_time("Запущена функция регистрации обменника...")
        # Логерд для режима отладки
        @debug "Параметры вызова функции:"
        @debug "> канал соединения с сервером RabbitMQ" channel
        @debug "> идентификатор обменника" exc_id
        @debug "> тип обменника" exc_type
        # Инициализируем переменную типа обменника с пустым значением
        exchange_type = nothing
        # Задаём тип обменника в зависимости от переданного наименования типа
        if exc_type == "direct"
            exchange_type = AMQPClient.EXCHANGE_TYPE_DIRECT
        elseif exc_type == "fanout"
            exchange_type = AMQPClient.EXCHANGE_TYPE_FANOUT
        elseif exc_type == "topic"
            exchange_type = AMQPClient.EXCHANGE_TYPE_TOPIC
        elseif exc_type == "headers"
            exchange_type = AMQPClient.EXCHANGE_TYPE_HEADERS
        else
            exchange_type = AMQPClient.EXCHANGE_TYPE_DIRECT
        end
        # Дополняем логирвание для режима отладки
        @debug ">> вычисленный тип обменника" exchange_type
        # Пытаемся объявить обменник
        try
            # Вызываем операцию объявления (регистрации) обменника на сервер RabbitMQ
            result::Bool = AMQPClient.exchange_declare(channel, exc_id, exchange_type)
            # Дополняем логирование для режима отладки
            @debug ">> результат операции регистрации обменника" result
            # В зависимости от результата операции задаём значение сообщения для
            # информационног уровня логирования и выводим его
            message::String = result ? "Регистрация обменника прошла успешно" : "Не удалось ззарегистрировать обменник"
            @info string("=> ", message)
            # В качестве результата возвращаем словарь, содержащий ключи:
            # NAME - наименование обменника
            # TYPE - тип обменника
            return Dict{String, Any}(
                "NAME" => exc_id,
                "TYPE" => exchange_type
            )
        catch error
            # Обрабатываем ошибки: выводим в терминал и кидаем исключение
            @error Chronometer.message_with_time("Удаление обменника завершилось ошибкой") error
            throw(error)
        end
    end
end
