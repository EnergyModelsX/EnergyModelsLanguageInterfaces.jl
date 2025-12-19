@testset "MultipleBuildingTypes" begin
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
            EMB.capacity(buildings, t, p) + value.(m[:buildings_surplus][buildings, t, p])
            for t ∈ 𝒯, p ∈ inputs(buildings)
        )

        @test all(
            sum(value.(m[:buildings_deficit][buildings, t, p]) for p ∈ inputs(buildings)) ==
            value.(m[:sink_deficit][buildings, t])
            for t ∈ 𝒯
        )

        @test all(
            sum(value.(m[:buildings_surplus][buildings, t, p]) for p ∈ inputs(buildings)) ==
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

        # Test the utility functions for MultipleBuildingTypes
        for p ∈ building_res
            # Capacity
            @test EMB.capacity(buildings) isa Dict
            @test EMB.capacity(buildings, p) isa TimeProfile
            @test EMB.capacity(buildings)[p] == EMB.capacity(buildings, p)
            @test EMB.capacity(buildings, first(𝒯), p) ==
                  EMB.capacity(buildings, p)[first(𝒯)]

            # Surplus penalty
            @test EMB.surplus_penalty(buildings) isa Dict
            @test EMB.surplus_penalty(buildings, p) isa TimeProfile
            @test EMB.surplus_penalty(buildings)[p] == EMB.surplus_penalty(buildings, p)
            @test EMB.surplus_penalty(buildings, first(𝒯), p) ==
                  EMB.surplus_penalty(buildings, p)[first(𝒯)]

            # Deficit penalty
            @test EMB.deficit_penalty(buildings) isa Dict
            @test EMB.deficit_penalty(buildings, p) isa TimeProfile
            @test EMB.deficit_penalty(buildings)[p] == EMB.deficit_penalty(buildings, p)
            @test EMB.deficit_penalty(buildings, first(𝒯), p) ==
                  EMB.deficit_penalty(buildings, p)[first(𝒯)]
        end

        # Test has_capacity utility function
        @test EMB.has_capacity(buildings) == false
    end
end
