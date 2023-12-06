import Base.length
import Base.first
import Base.last

using BenchmarkTools

if length(ARGS) < 1
    println("Need a calibration document file as a command-line argument")
    exit()
end

function debugmsg(s)
    println(s)
end

# this is to avoid the "hack" of julia ranges
struct SeedRange
    src::Int
    len::Int
end

function first(x::SeedRange)
    x.src
end
function last(x::SeedRange)
    x.src+x.len-1
end
function length(x::SeedRange)
    x.len
end

struct Mapping
    dst::Int
    src::Int
    len::Int
end
function first(m::Mapping)
    m.src
end
function last(m::Mapping)
    m.src + m.len - 1
end
function length(m::Mapping)
    m.len
end

function readmapping(line::String)::Mapping
    d, s, l = parse.(Int, split(line))
    Mapping(d, s, l)
end

# unused
function intersect(sr::SeedRange, mp::Mapping)::SeedRange
    offset = first(sr) - first(mp)

    if last(sr) < first(mp) || last(mp) < first(sr)
        # no intersection
        return nothing
    end
    if first(mp) <= first(sr) <= last(mp)
    elseif first(mp) <= last(sr) <= last(mp)
    elseif first(sr) < first(mp) && last(sr) > last(mp)
        # two tails
    end
end

function applymappings!(seedmaps::Array{Tuple{SeedRange, SeedRange}}, mappings::Array{Mapping})
    rmaps = Tuple{SeedRange, SeedRange}[]
    extramaps = Tuple{SeedRange, SeedRange}[]
    # s is the original seed range, not to be messed with, only split
    smcount = 0
    smtotal = length(seedmaps)
    while seedmaps |> !isempty
        (s, t) = popfirst!(seedmaps)
        smcount += 1
        remapped = false
        #debugmsg(" (seedmaps $(smcount) / $(smtotal) :: trying to remap $(t)")
        for m in mappings
            # handle seed range t and mapping m
            #debugmsg("checking if mapping $(m) applies to $(t)...")
            if first(m) <= first(t) <= last(m) ||
                first(m) <= last(t) <= last(m)

                #debugmsg("mapping $(m) applies to $(t)!")
                remapped = true
                offset = first(t) - first(m)
                #debugmsg("Offset: $(offset)")

                # first handle unmapped tails, if any
                tail_left = max(first(m) - first(t), 0)
                tail_right = max(last(t) - last(m), 0)
                #debugmsg("Tail lengths (left, right): ($(tail_left), $(tail_right))")

                if tail_left > 0
                    sr_left = SeedRange(first(t), tail_left)
                    #debugmsg("Left tail: $(sr_left)")
                    push!(seedmaps, (s, sr_left))
                end
                if tail_right > 0
                    sr_right = SeedRange(last(m)+1, tail_right)
                    #debugmsg("Right tail: $(sr_right)")
                    push!(seedmaps, (s, sr_right))
                end

                # remap the overlapping part
                map_delta = m.dst - m.src
                newrange_start = max(first(m), first(t)) + map_delta
                newrange_end = min(last(m), last(t)) + map_delta
                newrange_length = newrange_end - newrange_start + 1
                #debugmsg("remapping to $(newrange_start):$(newrange_end) len=$(newrange_length)")

                push!(rmaps, (s, SeedRange(newrange_start, newrange_length)))

                # this range has ceased to exist; no other mappings can apply
                # except to the tails which were re-added separately
                break
            end
        end
        if !remapped
            push!(rmaps, (s, t))
        end
    end
    rmaps
end

function seedparsev1(sline)
    seedmap = Tuple{SeedRange, SeedRange}[]
    seedliststr = split(sline, ':')[2]
    for seed in parse.(Int, split(seedliststr))
        sr = SeedRange(seed, 1)
        push!(seedmap, (sr, sr))
    end
    seedmap
end

function seedparsev2(sline)
    seedmap = Tuple{SeedRange, SeedRange}[]
    seedliststr = split(sline, ':')[2]
    seeds = parse.(Int, split(seedliststr))
    for (ss, sl) in Iterators.partition(seeds, 2)
        sr = SeedRange(ss, sl)
        # seedmap starts as the identity function
        # the second value (last()/[2]) has remappings applied until
        # it reaches its final destination
        push!(seedmap, (sr, sr))
    end
    seedmap
end

function parse_and_apply(f)
    seedmap = Tuple{SeedRange, SeedRange}[]
    mappage = Mapping[]  # per-section list of mappings
    lineno = 0
    state = :seeds
    for line in eachline(f)
        lineno += 1
        sline = strip(line)
        #debugmsg("Read line $(lineno): $(sline)")
        if state == :seeds
            if startswith(sline, "seeds:")
                seedmap = seedparsev2(sline)
                #debugmsg("Read seeds line, transitioning to map search")
                #debugmsg("starting state has $(length(seedmap)) segments...")
                state = :mapheader
            end
        elseif state == :mapheader
            if occursin(" map:", sline)
                # not necessary, just descriptive
                m = match(r"^([a-z]+)-to-([a-z]+) map:", sline)
                if !isnothing(m)
                    #debugmsg("reading $(m[1]) -to- $(m[2]) mapping...")
                end
                state = :mapline
            end
        elseif state == :mapline
            if length(sline) == 0
                #debugmsg("Blank line (end of one set of maps) found.")
                ml = length(mappage)
                if ml > 0
                    #debugmsg("applying $(ml) existing maps...")
                    seedmap = applymappings!(seedmap, mappage)
                else
                    #debugmsg("no maps to apply. either after seed spec or a malformed maps section")
                end

                # mapping of all seeds done, clear mappage
                #debugmsg("Clearing maps for next set")
                mappage = Mapping[]
                state = :mapheader
            else
                # should be a mapping line; parse, and add to mappage
                ml = readmapping(line)
                push!(mappage, ml)
            end
        else
            #debugmsg("Other state: $(state)")
        end
    end
    # end of file, check for non-empty map
    if length(mappage) > 0
        seedmap = applymappings!(seedmap, mappage)
    end
    seedmap
end


function main(args)
    for f in args
        @btime locations = parse_and_apply($f)
        locations = parse_and_apply(f)
        #@time locations = parse_and_apply(f)
 
        #debugmsg("locations: $(locations)")
        @time mv = findmin(srt -> first(last(srt)), locations)
        println("lowest numbered location: $(mv)")

        println("Total number of segments after processing: $(length(locations))")
    end
end


main(ARGS)

