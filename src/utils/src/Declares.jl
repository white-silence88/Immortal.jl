module Declares

    # Импортируем бибилиотеку работы со временем
    include("Chronometer.jl")
    import .Chronometer

    export queues, exchangers, in_channel

    """ Функция регистрации очередей по именам.

    channel: канал связи с брокером
    queues_names: список имён очередей
    Adapter: адаптер брокера очередей
    """
    function queues(channel, queues_names, Adapter)
        @info Chronometer.message_with_time("Выполняется функция регистрации очередей...")

        @debug "Параметры вызова функции:"
        @debug "> канал связи с брокером" channel
        @debug "> список имён очередей" queues_names
        @debug "> адаптер брокера очередей" Adapter

        queues = nothing 
        @debug "Инициализируем пустой список очередей" queues

        @debug "Перебираем имена очередей и регистрируем каждую"
        for name in queues_names
            @debug "> Имя для регистрации очереди" name

            queue = Adapter.Queues.declare(channel, name)
            @debug "> Зарегистрированная очередь" queue

            if queue !== nothing
                if queues === nothing
                    queues = Dict{String, Any}(name => queue)
                    @debug ">> Создали словарь зарегистрированных очередей" queues
                else
                    push!(queues, name => queue)
                    @debug ">> Обновили словарь зарегистрированных очередей" queues
                end
            end
        end
        
        @debug "Список зарегистрированных очередей" queues
        return queues
    end

    """ Функция регистрации обменников.

    channel: канал связи с брокером
    exchanger_config: конфигурация обменников
    Adapter: адаптер брокера очередей
    """
    function exchangers(channel, exchangers_configs, Adapter)
        @info Chronometer.message_with_time("Выполняется функция регистрации обменников...")

        @debug "Параметры вызова функции:"
        @debug "- канал связи с брокером" channel
        @debug "- конфигурации обменников канала" exchangers_configs
        @debug "- адаптер брокера очередей" Adapter

        exchangers = nothing
        @debug "Инициализируем пустое значение словаря обменников" exchangers
        
        name_field::String = "name"
        @debug "Имя поля наименования обменника" name_field
        
        type_field::String = "type"
        @debug "Имя поля типа обменника" type_field

        @debug "Перебираем список настроек объетов конфигурации обменников и регистрируем их"
        for exchanger_config in exchangers_configs
            @debug "> Конфигурация обмненика" exchanger_config

            name = get(exchanger_config, name_field, nothing)
            @debug "> Имя обменника из конфигурации" name

            type = get(exchanger_config, type_field, "direct")
            @debug "> Тим обменника из конфигурации" type

            if name !== nothing
                exchanger::Dict{String, Any} = Adapter.Exchanges.declare(channel, name, type)
                @debug ">> Зарегистрированный обменник" exchanger

                if exchangers === nothing
                    exchangers = Dict{String, Any}(name => exchanger)
                    @debug ">>> Создали словарь зарегистрированных обменников" exchangers
                else
                    push!(exchangers, name => exchanger)
                    @debug ">>> Обновоили словарь зарегистрированных обменников" exchangers
                end
            end
        end

        @debug "Зарегистрированные обменники" exchangers
        return exchangers
    end

    """ Функця регистрации очередей и обмеников в канале

    channel: канал связи с брокером
    channel_config: конфигурация канала
    Adapter: адаптер брокера
    """
    function in_channel(channel, channel_config, Adapter)
        @info Chronometer.message_with_time("Выполняется функция регистрации очередей, обменников и т.п. в канале...")

        @debug "Параметры вызова функции:"
        @debug "- канал связи с брокером" channel
        @debug "- конфигурация канала" channel_config
        @debug "- адаптер брокера" Adapter


        exchangers_dict = nothing
        @debug "Задаём пустое значение для зарегистрированных обменников" exchangers_dict

        queues_dict = nothing
        @debug "Задаём пустое значене для зарегистрированных очередей" queues_dict

        queues_field::String = "queues"
        exchangers_field::String = "exchangers"
        @debug "Имя поля конфигурации очередей" queues_field
        @debug "Имя поля конфигурации обменников" exchangers_field

        @debug "Проверяем наличие конфигурации канала и самого канала, если все есть - регистрируем очереди и обменники"
        if channel_config !== nothing && channel !== nothing
            exchangers_list = get(channel_config, exchangers_field, nothing)
            @debug "> Список настроек для обменников из конфигурации" exchangers_list 

            queues_list = get(channel_config, queues_field, nothing)
            @debug "> Список настроек для обнменников из конфигурации" queues_list

            exchangers_dict = exchangers(channel, exchangers_list, Adapter)
            @debug "> Словарь зарегистрированных обменников" exchangers_dict

            queues_dict = queues(channel, queues_list, Adapter)
            @debug "> Словарь зарегистрированных очередей" queues_dict
        end

        @debug "Зарегистрированные обменники" exchangers_dict
        @debug "Зарегистрированные очереди" queues_dict
        return exchangers_dict, queues_dict
    end
end