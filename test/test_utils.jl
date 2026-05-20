@testset "heat_demand_profile utility function" begin
    for _ ∈ 1:2 # Run the test two times to also test running from stored files (from first run)
        profiles = []
        for source ∈ ["NORA3", "ERA5"]
            df = get_heat_demand_profile(; source)
            push!(profiles, df.heat_demand)
        end

        ref_values = [
            [
                12.37,
                12.26,
                12.09,
                12.08,
                11.92,
                12.74,
                13.71,
                13.81,
                13.91,
                13.77,
                13.79,
                13.75,
                14.29,
                14.65,
                14.98,
                16.54,
                15.52,
                15.87,
                16.14,
                16.16,
                16.18,
                16.17,
                16.07,
                16.53,
            ],
            [
                12.01,
                11.91,
                11.76,
                11.61,
                11.49,
                12.22,
                13.07,
                13.11,
                13.14,
                13.14,
                13.27,
                13.26,
                13.87,
                14.51,
                14.6,
                14.7,
                14.57,
                14.98,
                15.19,
                15.26,
                15.09,
                15.12,
                14.87,
                15.05,
            ],
        ]

        for (ref_value, profile) ∈ zip(ref_values, profiles)
            @test isapprox(
                ref_value,
                profile;
                atol = TEST_ATOL,
            )
        end
    end
end
