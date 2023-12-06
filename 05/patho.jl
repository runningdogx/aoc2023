function main(s1::Int, m1::Int)
    seedranges = UnitRange[]
    dupcount = 0
    print("seeds:")
    while length(seedranges) < s1
        sv = rand(0:2_000_000_000)
        sl = rand(10_000_000:200_000_000)
        if dupcount > 1000
            sl = rand(10_000:10_000_000)
        end
        sr = sv:sv+sl
        dup = false
        for preexisting in seedranges
            if intersect(sr, preexisting) |> !isempty
                dup = true
                dupcount += 1
                break
            end
        end
        if !dup
            push!(seedranges, sr)
            print(" $(first(sr)) $(length(sr))")
        end
    end
    println()
    #println("$(dupcount) dups while making initial seed ranges")

    maptypes = [ :seed,  :soil,        :fertilizer, :water,
                 :light, :temperature, :humidity,   :location]
    for mapidx in 1:length(maptypes)-1
        println("\n$(string(maptypes[mapidx]))-to-$(string(maptypes[mapidx+1])) map:")

        mapsr = UnitRange[]
        dupcount = 0
        while length(mapsr) < m1
            mdst = rand(0:2_000_000_000)
            msrc = rand(0:2_000_000_000)
            ml = rand(10_000_000:200_000_000)
            # large or small length?
            smol = rand(0:1)
            if dupcount > 1000
                ml = rand(10_000:10_000_000)
            end
            r = msrc:msrc+ml
            dup = false
            for preexisting in mapsr
                if intersect(r, preexisting) |> !isempty
                    dup = true
                    dupcount += 1
                    break
                end
            end
            if !dup
                push!(mapsr, r)
                println("$(mdst) $(msrc) $(ml)")
            end
        end
        #println("$(dupcount) dups while making map")
    end
end


seedranges = 50
if length(ARGS) > 0
    seedranges = tryparse(Int, ARGS[1])
end
mapsper = 100
if length(ARGS) > 1
    mapsper = tryparse(Int, ARGS[2])
end
main(seedranges, mapsper)

"""
seed-to-soil map:
soil-to-fertilizer map:
fertilizer-to-water map:
water-to-light map:
light-to-temperature map:
temperature-to-humidity map:
humidity-to-location map:
"""
