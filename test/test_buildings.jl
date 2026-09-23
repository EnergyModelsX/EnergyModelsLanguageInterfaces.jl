@testset "MultipleBuildingTypes" begin
    @testset "Utilities" begin
        # Create the general data for the building node
        𝒯 = TwoLevel(2, 1, SimpleTimes(4, 1))
        heat = ResourceCarrier("Heat", 0.0)
        power = ResourceCarrier("Power", 0.0)
        building_node = MultipleBuildingTypes(
            "Building",
            Dict(heat => FixedProfile(100), power => FixedProfile(50)),
            Dict(heat => FixedProfile(10), power => FixedProfile(5)),
            Dict(heat => FixedProfile(20), power => FixedProfile(10)),
            Dict(heat => 1.0, power => 0.5),
        )

        # Test the EMB utility functions
        @test EMB.capacity(building_node) ==
              Dict(heat => FixedProfile(100), power => FixedProfile(50))
        @test EMB.capacity(building_node, heat) == FixedProfile(100)
        @test EMB.capacity(building_node, power) == FixedProfile(50)
        @test EMB.capacity(building_node, first(𝒯), heat) == 100
        @test EMB.capacity(building_node, first(𝒯), power) == 50
        @test EMB.surplus_penalty(building_node) ==
              Dict(heat => FixedProfile(10), power => FixedProfile(5))
        @test EMB.surplus_penalty(building_node, heat) == FixedProfile(10)
        @test EMB.surplus_penalty(building_node, power) == FixedProfile(5)
        @test EMB.surplus_penalty(building_node, first(𝒯), heat) == 10
        @test EMB.surplus_penalty(building_node, first(𝒯), power) == 5
        @test EMB.deficit_penalty(building_node) ==
              Dict(heat => FixedProfile(20), power => FixedProfile(10))
        @test EMB.deficit_penalty(building_node, heat) == FixedProfile(20)
        @test EMB.deficit_penalty(building_node, power) == FixedProfile(10)
        @test EMB.deficit_penalty(building_node, first(𝒯), heat) == 20
        @test EMB.deficit_penalty(building_node, first(𝒯), power) == 10
        @test heat ∈ EMB.inputs(building_node)
        @test power ∈ EMB.inputs(building_node)
        @test EMB.has_capacity(building_node) == false
    end

    @testset "Mathematical formulation" begin
        for _ ∈ 1:2 # Run the test two times to also test running from stored files (from first run)
            case, modeltype = simple_graph_buildings()

            buildings = get_node(case, "Buildings")  # The MultipleBuildingTypes node
            products = get_products(case)
            building_res = products[1:(end-1)]  # All resources except CO2
            CO2 = products[end]  # The CO2 resource

            # Run the model
            m = EMB.run_model(case, modeltype, OPTIMIZER)

            # Extraction of the time structure
            𝒯 = get_time_struct(case)

            # Run of the general tests
            general_tests(m)

            @test all(
                value.(m[:buildings_surplus][buildings, t, p]) == 0.0 for
                t ∈ 𝒯, p ∈ building_res
            )
            @test all(
                value.(m[:buildings_deficit][buildings, t, p]) == 0.0 for
                t ∈ 𝒯, p ∈ building_res
            )
            @test all(value.(m[:emissions_total][t, CO2]) > 1e3 for t ∈ 𝒯)

            # Test that the EMB function has_capacity is false for the MultipleBuildingTypes node.
            @test !EMB.has_capacity(buildings)

            # Test constraints from EMB.constraints_capacity
            @test all(
                value.(m[:flow_in][buildings, t, p]) / inputs(buildings, p) +
                value.(m[:buildings_deficit][buildings, t, p]) ==
                EMB.capacity(buildings, t, p) +
                value.(m[:buildings_surplus][buildings, t, p])
                for t ∈ 𝒯, p ∈ inputs(buildings)
            )

            @test all(
                sum(
                    value.(m[:buildings_deficit][buildings, t, p]) for p ∈ inputs(buildings)
                ) ==
                value.(m[:sink_deficit][buildings, t])
                for t ∈ 𝒯
            )

            @test all(
                sum(
                    value.(m[:buildings_surplus][buildings, t, p]) for p ∈ inputs(buildings)
                ) ==
                value.(m[:sink_surplus][buildings, t])
                for t ∈ 𝒯
            )

            # Test constraints from EMB.constraints_opex_var
            𝒯ᴵⁿᵛ = strategic_periods(𝒯)
            @test all(
                value.(m[:opex_var][buildings, t_inv]) ==
                sum(
                    (
                        value.(m[:buildings_surplus][buildings, t, p]) *
                        EMB.surplus_penalty(buildings, t, p) +
                        value.(m[:buildings_deficit][buildings, t, p]) *
                        EMB.deficit_penalty(buildings, t, p)
                    ) * scale_op_sp(t_inv, t) for t ∈ t_inv, p ∈ inputs(buildings)
                )
                for t_inv ∈ 𝒯ᴵⁿᵛ
            )
        end
    end
end
