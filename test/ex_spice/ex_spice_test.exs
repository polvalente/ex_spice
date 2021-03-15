defmodule ExSpiceTest do
  use ExUnit.Case, async: true

  doctest ExSpice

  describe "DC Simulation" do
    test "RC circuit" do
      netlist = """
      R1 0 1 1
      R2 1 2 3
      C1 0 1 1
      I1 0 2 1
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.CurrentSource{
                   name: "I1",
                   node_neg: 2,
                   node_pos: 0,
                   value: 1.0
                 },
                 %ExSpice.Components.Capacitor{name: "C1", nodes: [0, 1], value: 1.0},
                 %ExSpice.Components.Resistor{name: "R2", nodes: [1, 2], value: 3.0},
                 %ExSpice.Components.Resistor{name: "R1", nodes: [0, 1], value: 1.0}
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{"0" => 0, "1" => 1, "2" => 2, "jC1" => 3} == variables

      assert Nx.round(Nx.tensor([0.0, 1.0, 4.0, 0])) == Nx.round(solution)
    end

    test "RL circuit" do
      netlist = """
      R1 0 1 1
      R2 1 2 3
      L1 3 2 1
      I1 0 3 1
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.CurrentSource{
                   name: "I1",
                   node_neg: 3,
                   node_pos: 0,
                   value: 1.0
                 },
                 %ExSpice.Components.Inductor{name: "L1", nodes: [3, 2], value: 1.0, current: 4},
                 %ExSpice.Components.Resistor{name: "R2", nodes: [1, 2], value: 3.0},
                 %ExSpice.Components.Resistor{name: "R1", nodes: [0, 1], value: 1.0}
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{"0" => 0, "1" => 1, "2" => 2, "3" => 3, "jL1" => 4} == variables

      assert Nx.round(Nx.tensor([0.0, 1.0, 4.0, 4.0, 1.0])) == Nx.round(solution)
    end

    test "RLC circuit" do
      netlist = """
      R1 0 1 1
      R2 1 2 3
      L1 3 2 1
      C1 3 2 1
      I1 0 3 1
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.CurrentSource{
                   name: "I1",
                   node_neg: 3,
                   node_pos: 0,
                   value: 1.0
                 },
                 %ExSpice.Components.Capacitor{name: "C1", nodes: [3, 2], value: 1.0, current: 5},
                 %ExSpice.Components.Inductor{name: "L1", nodes: [3, 2], value: 1.0, current: 4},
                 %ExSpice.Components.Resistor{name: "R2", nodes: [1, 2], value: 3.0},
                 %ExSpice.Components.Resistor{name: "R1", nodes: [0, 1], value: 1.0}
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{"0" => 0, "1" => 1, "2" => 2, "3" => 3, "jL1" => 4, "jC1" => 5} == variables

      assert Nx.round(Nx.tensor([0.0, 1.0, 4.0, 4.0, 1.0, 0.0])) == Nx.round(solution)
    end

    test "OpAmp RLC circuit" do
      netlist = """
      R1 Vin V+ 1
      R2 V+ Vo 2
      R3 3  Vo 2
      L1 3 V+ 1
      C1 V+ Vo 1
      O1 Vo 0 V+ 0
      I1 0 Vin 1
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.CurrentSource{
                   name: "I1",
                   node_neg: 1,
                   node_pos: 0,
                   value: 1.0
                 },
                 %ExSpice.Components.OpAmp{
                   name: "O1",
                   current: 7,
                   node_in_neg: 0,
                   node_in_pos: 2,
                   node_out_neg: 0,
                   node_out_pos: 3
                 },
                 %ExSpice.Components.Capacitor{name: "C1", nodes: [2, 3], value: 1.0, current: 6},
                 %ExSpice.Components.Inductor{name: "L1", nodes: [4, 2], value: 1.0, current: 5},
                 %ExSpice.Components.Resistor{name: "R3", nodes: [4, 3], value: 2.0},
                 %ExSpice.Components.Resistor{name: "R2", nodes: [2, 3], value: 2.0},
                 %ExSpice.Components.Resistor{name: "R1", nodes: [1, 2], value: 1.0}
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{
               "0" => 0,
               "Vin" => 1,
               "V+" => 2,
               "Vo" => 3,
               "3" => 4,
               "jL1" => 5,
               "jC1" => 6,
               "jO1" => 7
             } == variables

      assert Nx.round(Nx.tensor([0.0, 1.0, 0.0, -1.0, 0.0, -1.0, 0.0, 1.0])) == Nx.round(solution)
    end

    test "OpAmp RLC circuit with Vin" do
      netlist = """
      V1 Vin 0 10
      R1 Vin V+ 1
      R2 V+ Vo 2
      R3 3  Vo 2
      L1 3 V+ 1
      C1 V+ Vo 1
      O1 Vo 0 V+ 0
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.OpAmp{
                   name: "O1",
                   current: 8,
                   node_in_neg: 0,
                   node_in_pos: 3,
                   node_out_neg: 0,
                   node_out_pos: 4
                 },
                 %ExSpice.Components.Capacitor{name: "C1", nodes: [3, 4], value: 1.0, current: 7},
                 %ExSpice.Components.Inductor{name: "L1", nodes: [5, 3], value: 1.0, current: 6},
                 %ExSpice.Components.Resistor{name: "R3", nodes: [5, 4], value: 2.0},
                 %ExSpice.Components.Resistor{name: "R2", nodes: [3, 4], value: 2.0},
                 %ExSpice.Components.Resistor{name: "R1", nodes: [1, 3], value: 1.0},
                 %ExSpice.Components.VoltageSource{
                   name: "V1",
                   node_neg: 0,
                   node_pos: 1,
                   value: 10.0
                 }
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{
               "0" => 0,
               "Vin" => 1,
               "jV1" => 2,
               "V+" => 3,
               "Vo" => 4,
               "3" => 5,
               "jL1" => 6,
               "jC1" => 7,
               "jO1" => 8
             } == variables

      assert Nx.round(Nx.tensor([0.0, 10, -10.0, 0.0, -10, 0.0, -5, 0.0, 10])) ==
               Nx.round(solution)
    end

    test "CCCS" do
      netlist = """
      I1 1 0 1
      F1 2 0 3 1 2
      R1 2 0 1
      R2 3 0 1
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.Resistor{
                   name: "R2",
                   nodes: [3, 0],
                   value: 1.0
                 },
                 %ExSpice.Components.Resistor{
                   name: "R1",
                   nodes: [2, 0],
                   value: 1.0
                 },
                 %ExSpice.Components.CurrentControlledCurrentSource{
                   current: 4,
                   gain: 2.0,
                   name: "F1",
                   node_in_neg: 1,
                   node_in_pos: 3,
                   node_out_neg: 0,
                   node_out_pos: 2
                 },
                 %ExSpice.Components.CurrentSource{
                   name: "I1",
                   node_neg: 0,
                   node_pos: 1,
                   value: 1.0
                 }
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{"0" => 0, "1" => 1, "2" => 2, "3" => 3, "jF1" => 4} == variables

      assert Nx.round(Nx.tensor([0.0, -1.0, 2.0, -1, 1])) ==
               Nx.round(solution)
    end

    test "VCVS" do
      netlist = """
      I1 1 0 1
      F1 2 0 3 1 2
      R1 2 0 1
      R2 3 0 1
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.Resistor{
                   name: "R2",
                   nodes: [3, 0],
                   value: 1.0
                 },
                 %ExSpice.Components.Resistor{
                   name: "R1",
                   nodes: [2, 0],
                   value: 1.0
                 },
                 %ExSpice.Components.CurrentControlledCurrentSource{
                   current: 4,
                   gain: 2.0,
                   name: "F1",
                   node_in_neg: 1,
                   node_in_pos: 3,
                   node_out_neg: 0,
                   node_out_pos: 2
                 },
                 %ExSpice.Components.CurrentSource{
                   name: "I1",
                   node_neg: 0,
                   node_pos: 1,
                   value: 1.0
                 }
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{"0" => 0, "1" => 1, "2" => 2, "3" => 3, "jF1" => 4} == variables

      assert Nx.round(Nx.tensor([0.0, -1.0, 2.0, -1, 1])) ==
               Nx.round(solution)
    end

    test "CCVS" do
      #                1
      #  1_2___     3__r2______4
      #  |    |      |         |
      #  r1=1 V=2    H=10*I12  r3 = 1
      #  |    |      |         |
      #  g    g      g         g

      netlist = """
      R1 1 0 1
      V1 2 0 2
      H1 0 3 1 2 10
      R2 3 4 1
      R3 4 0 1
      """

      assert %ExSpice.Netlist{
               components: [
                 %ExSpice.Components.Resistor{
                   name: "R3",
                   nodes: [7, 0],
                   value: 1.0
                 },
                 %ExSpice.Components.Resistor{
                   name: "R2",
                   nodes: [4, 7],
                   value: 1.0
                 },
                 %ExSpice.Components.CurrentControlledVoltageSource{
                   gain: 10.0,
                   name: "H1",
                   node_in_neg: 2,
                   node_in_pos: 1,
                   node_out_neg: 4,
                   node_out_pos: 0,
                   current_in: 5,
                   current_out: 6
                 },
                 %ExSpice.Components.VoltageSource{
                   name: "V1",
                   node_neg: 0,
                   node_pos: 2,
                   value: 2.0,
                   current: 3
                 },
                 %ExSpice.Components.Resistor{name: "R1", nodes: [1, 0], value: 1.0}
               ],
               solution: solution,
               variables: variables
             } = netlist |> ExSpice.parse() |> ExSpice.simulate(mode: :dc)

      assert %{
               "0" => 0,
               "1" => 1,
               "2" => 2,
               "jV1" => 3,
               "3" => 4,
               "jxH1" => 5,
               "jyH1" => 6,
               "4" => 7
             } == variables

      assert Nx.round(Nx.tensor([0.0, 2.0, 2.0, -2.0, 20.0, -2.0, 10.0, 10.0])) ==
               Nx.round(solution)
    end

    test "VCCS"
    test "Diode"
    test "Transformer"
  end
end
