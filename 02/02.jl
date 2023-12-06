
if length(ARGS) < 1
    println("Need a calibration document file as a command-line argument")
    exit()
end

struct ElGa
    gameno::Int
    reds::Int
    greens::Int
    blues::Int
end

function elfgame1(f)
    gamelist = Array{ElGa}(undef, 0)
    lineno = 0
    for line in eachline(f)
        lineno += 1
        s = strip.(split(line, [':', ';']))
        gnraw = popfirst!(s)
        m = match(r"^Game ([1-9]\d*)$", gnraw)
        if isnothing(m)
            println("No game specifier for line $(lineno): $(line)")
            continue
        end
        gn = tryparse(Int, m[1])

        redmax, greenmax, bluemax = (0,0,0)
        for sample in s
            clrsamples = strip.(split(sample, ','))
            for clrsample in clrsamples
                m = match(r"^([1-9]\d*) (red|green|blue)$", clrsample)
                if isnothing(m)
                    println("strange color sample on line $(lineno): $(clrsample)")
                    continue
                end
                iv = tryparse(Int, m[1])
                if iv === nothing
                    println("Couldn't parse number of cubes on line $(lineno): $(clrsample)")
                    continue
                end
                if m[2] == "red"
                    redmax = max(redmax, iv)
                elseif m[2] == "green"
                    greenmax = max(greenmax, iv)
                elseif m[2] == "blue"
                    bluemax = max(bluemax, iv)
                end
            end
        end
        push!(gamelist, ElGa(gn, redmax, greenmax, bluemax))
    end
    gamelist
end



function main(args)
    local sum::Int
    for f in args
        @time eg = elfgame1(f)
        println(eg)
        egf = filter(x -> x.reds <= 12 && x.greens <= 13 && x.blues <= 14, eg)
        gsum = mapreduce(x -> x.gameno, +, egf)
        println("Game ID sum: $(gsum)")

        p2sum = mapreduce(x-> x.reds * x.greens * x.blues, +, eg)
        println("Power set sum: $(p2sum)")
    end
end


main(ARGS)

