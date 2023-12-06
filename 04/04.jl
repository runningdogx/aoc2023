if length(ARGS) < 1
    println("Need a calibration document file as a command-line argument")
    exit()
end

function parsecard(line)::Tuple{Int, Int}
    cardno, winning_r, have_r = strip.(split(line, [':', '|']))
    winning = tryparse.(Int, split(winning_r))
    have = tryparse.(Int, split(have_r))
    count = length(intersect(winning, have))
    cnm = match(r"Card\s+([1-9]\d*)", cardno)
    (tryparse(Int, cnm[1]), count)
end

function parseall1(f)
    cardsum = 0
    for line in eachline(f)
        cardno, matching = parsecard(strip(line))
        if matching > 0
            # 1 -> 1, 2-> 2, 3 -> 4, 4 -> 8   :: 2^(count-1)
            cardsum += 2^(matching-1)
        end
    end
    cardsum
end

function parseall2(f)
    totalcards = 0
    # could use a dict, but that wouldn't be any fun
    # this is a look-ahead card count, expanded as needed
    nextn = ones(Int, 0)
    for line in eachline(f)
        cardno, matching = parsecard(strip(line))
        if length(nextn) == 0
            repeats = 1
        else
            repeats = popfirst!(nextn)
        end
        println("card $(cardno), $(matching) matches, $(repeats) repeats")
        totalcards += repeats # this tracks the total
        if matching > 0
            delta = matching - length(nextn)
            # expand nextn to accommodate next n matching cards
            if delta > 0
                append!(nextn, ones(Int, delta))
            end
            for idx in 1:matching
                nextn[idx] += repeats
            end
        end
    end
    totalcards
end


function main(args)
    local sum::Int
    for f in args
        @time cardsum = parseall1(f)
        println("Sum: $(cardsum)")

        @time totalcards = parseall2(f)
        println("Total cards: $(totalcards)")
    end
end


main(ARGS)

