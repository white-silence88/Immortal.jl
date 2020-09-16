module Chronometer
    using Dates
    export message_with_time

    """Функция, которая возвращает строку, которая сформирована 
    из служебных символов, и времени вызова.


    message: сообщение, которое требуется обогатить датой и временем
    """
    function message_with_time(message)::String
        #TODO: добавить логер
        return string("<", Dates.now(), "> ", message)
    end
end
