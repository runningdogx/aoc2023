
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


function issymbol(chr)
    chr in "`~!@#\$%^&*()-_=+[]{}\\|;':\",<>/?"
end
function isstar(chr)
    chr in "*"
end

```
finds any symbols adjacent to an integer on the specified row at the specified colrange
```
function findsymbol(grid::Array{<:AbstractString}, row::Int, colrange::UnitRange)
    ret = false

    rowlen = length(grid[1])
    mincol = minimum(colrange)-1
    maxcol = maximum(colrange)+1
    erange = mincol:maxcol
    limits = intersect(1:rowlen, erange)  # clamp to actual string limits

    symbols = Array{Tuple}(undef, 0)
    #println("checking for symbol on row $(row), range $(colrange)")
    # check row above
    if row > 1
        prevrow = row - 1
        for c in limits
            if issymbol(grid[prevrow][c])
                #println("found symbol on prev row, position $(c)")
                if isstar(grid[prevrow][c])
                    push!(symbols, (prevrow, c))
                end
                ret = true
            end
        end
    end
    
    # check this row
    if minimum(colrange) > 1 && issymbol(grid[row][mincol])
        #println("found symbol before number")
        if isstar(grid[row][mincol])
            push!(symbols, (row, mincol))
        end
        ret = true
    elseif maximum(colrange) < length(grid[1]) && issymbol(grid[row][maxcol])
        #println("found symbol after number")
        if isstar(grid[row][maxcol])
            push!(symbols, (row, maxcol))
        end
        ret = true
    end

    # check row below
    if row < length(grid) # max rows in grid
        nextrow = row + 1
        for c in limits
            if issymbol(grid[nextrow][c])
                #println("found symbol on next row, position $(c)")
                if isstar(grid[nextrow][c])
                    push!(symbols, (nextrow, c))
                end
                ret = true
            end
        end
    end
    (ret, symbols)
end

function partnumbers(f)
    partlist = zeros(Int, 0)

    partgrid = strip.(readlines(f))
    filter!(x-> !isempty(x), partgrid)

    for lineno in eachindex(partgrid)
        #println("processing line: $(partgrid[lineno])")
        ranges = findall(r"\d+", partgrid[lineno])
        #println("digit ranges found: $(ranges)")
        for range in ranges
            foundsym, starlist = findsymbol(partgrid, lineno, range)
            if foundsym
                pn = tryparse(Int, partgrid[lineno][range])
                #println("Found part number $(pn)")
                push!(partlist, pn)
            end
        end
    end
    partlist
end

function gearratios(f)
    gearratios = zeros(Int, 0)

    partgrid = strip.(readlines(f))
    filter!(x-> !isempty(x), partgrid)

    tracker = Dict{Tuple, Any}()

    for lineno in eachindex(partgrid)
        #println("processing line: $(partgrid[lineno])")
        ranges = findall(r"\d+", partgrid[lineno])
        #println("digit ranges found: $(ranges)")
        for range in ranges
            foundsym, starlist = findsymbol(partgrid, lineno, range)
            if !isempty(starlist)
                pn = tryparse(Int, partgrid[lineno][range])
                #println("Found part number $(pn)")
                for starcoord in starlist
                    # update this star coordinate with the found part number
                    known = get(tracker, starcoord, Array{Int}(undef, 0))
                    push!(known, pn)
                    tracker[starcoord] = known
                end
            end
        end
    end
    filter(((k,v),) -> length(v)==2 , tracker)
end


function main(args)
    local sum::Int
    for f in args
        @time partlist = partnumbers(f)
        println(partlist)

        pnsum = reduce(+, partlist)
        println("Part number sum: $(pnsum)")

        @time gr = gearratios(f)
        println(gr)
        grsum = mapreduce(((k,v),) -> reduce(*, v), +, gr)
        println("gear ratio sum: $(grsum)")
    end
end


main(ARGS)

