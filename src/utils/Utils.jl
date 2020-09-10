module Utils
    include("./src/Chronometer.jl")
    import .Chronometer

    include("./src/FileReader.jl")
    import .FileReader
end