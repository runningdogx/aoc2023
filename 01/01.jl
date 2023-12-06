if length(ARGS) < 1
    println("Need a calibration document file as a command-line argument")
    exit()
end


function calibration1(f)
    sum = 0
    lineno = 0
    for line in eachline(f)
        lineno += 1
        first = findfirst(c -> c in '0':'9', line)
        last = findlast(c -> c in '0':'9', line)
        if first == nothing || last == nothing
            println("No digit found on line $(lineno): $(line)")
            continue
        end
        combined = tryparse(Int, string(line[first])) * 10 + tryparse(Int, string(line[last]))
        #println("read $(combined) on line $(lineno): $(line)")
        sum += combined
    end
    println("calib1, file $(f) sum: $(sum)")
end

calibmap = Dict([
                 "1" => 1,
                 "2" => 2,
                 "3" => 3,
                 "4" => 4,
                 "5" => 5,
                 "6" => 6,
                 "7" => 7,
                 "8" => 8,
                 "9" => 9,
                 "0" => 0,
                 "one" => 1,
                 "two" => 2,
                 "three" => 3,
                 "four" => 4,
                 "five" => 5,
                 "six" => 6,
                 "seven" => 7,
                 "eight" => 8,
                 "nine" => 9,
                 "zero" => 0,
                ])

function calibration2(f)
    sum = 0
    lineno = 0
    for line in eachline(f)
        lineno += 1
        cdigitrgx = r"([0-9]|zero|one|two|three|four|five|six|seven|eight|nine)"
        ranges = findall(cdigitrgx, line)
        if isempty(ranges)
            println("No digit found on line $(lineno): $(line)")
            continue
        end
        if lineno == 126
            println(ranges)
        end
        digit1 = get(calibmap, line[first(ranges)], 0)
        digit2 = get(calibmap, line[last(ranges)], 0)
        combined = digit1 * 10 + digit2
        #println("read $(combined) on line $(lineno): $(line)")
        sum += combined
    end
    println("calib2, file $(f) sum: $(sum)")
end
function calibration2b(f)
    sum = 0
    lineno = 0
    for line in eachline(f)
        lineno += 1
        cdigitrgx = r"([0-9]|zero|one|two|three|four|five|six|seven|eight|nine)"
        matches = collect(eachmatch(cdigitrgx, line, overlap=true))
        if isempty(matches)
            println("No digit found on line $(lineno): $(line)")
            continue
        end
        if lineno == 126
            println(matches)
        end
        digit1 = get(calibmap, first(matches)[1], 0)
        digit2 = get(calibmap, last(matches)[1], 0)
        combined = digit1 * 10 + digit2
        #println("read $(combined) on line $(lineno): $(line)")
        sum += combined
    end
    println("calib2, file $(f) sum: $(sum)")
end

function calibration3(f)
    sum = 0
    lineno = 0

    for line in eachline(f)
        lineno += 1
        val_start, val_end = -1, -1
        for sidx in 1:length(line)
            for substkey in keys(calibmap)
                if startswith(line[sidx:end], substkey)
                    if val_start == -1
                        val_start = calibmap[substkey]
                    end
                end
                if endswith(line[begin:end+1-sidx], substkey)
                    if val_end == -1
                        val_end = calibmap[substkey]
                    end
                end
            end
        end
        if val_start == -1 || val_end == -1
            println("No digit found on line $(lineno): $(line)")
            continue
        end
        if lineno == 126
            println("$(lineno): $(val_start) and $(val_end)")
        end
        combined = val_start * 10 + val_end
        #println("read $(combined) on line $(lineno): $(line)")
        sum += combined
    end
    println("calib3, file $(f) sum: $(sum)")

end


function main(args)
    local sum::Int
    for f in args
        @time calibration1(f)
        #calibration2(f)
        calibration2b(f)
        calibration3(f)
        @time calibration2b(f)
        @time calibration3(f)
    end
end


main(ARGS)

