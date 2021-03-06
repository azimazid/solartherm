within SolarTherm.Models.PowerBlocks;

model SurrogatesCO2PB_OTF

   /*                                               DEFINITION                                                                         */
  //          Cooling power belongs to parasities which makes during the sizing process, cooling power is not included                //
  //                W_gross is the power output before parasities i.e. heliostat, lift and cooling power consumption                  //
  
  extends SolarTherm.Media.CO2.PropCO2;
  import SI = Modelica.SIunits;
  import FI = SolarTherm.Models.Analysis.Finances;
  import SolarTherm.Utilities.Kriging_OnTheFly.*;
  import SolarTherm.Utilities.ANN_OnTheFly.*;
  replaceable package MedPB = SolarTherm.Media.CO2.CO2_ph;
  replaceable package MedRec = SolarTherm.Media.ChlorideSalt.ChlorideSalt_pT;
  extends Icons.PowerBlock;
 
  Modelica.Fluid.Interfaces.FluidPort_a fluid_a(redeclare package Medium = MedRec) annotation(
    Placement(visible = true, transformation(origin = {-74, 52}, extent = {{-6, -6}, {6, 6}}, rotation = 0), iconTransformation(extent = {{-48, 30}, {-40, 38}}, rotation = 0)));
  Modelica.Fluid.Interfaces.FluidPort_b fluid_b(redeclare package Medium = MedRec) annotation(
    Placement(visible = true, transformation(origin = {-90, 40}, extent = {{-6, -6}, {6, 6}}, rotation = 0), iconTransformation(extent = {{-62, -48}, {-54, -40}}, rotation = 0)));
  Modelica.Blocks.Interfaces.RealOutput W_net(quantity = "Power", unit = "W", displayUnit = "MW") "Net electric power output" annotation(
    Placement(visible = true, transformation(origin = {100, 0}, extent = {{-6, -6}, {6, 6}}, rotation = 0), iconTransformation(extent = {{46, -10}, {56, 0}}, rotation = 0)));
  Modelica.Blocks.Interfaces.BooleanInput ramping annotation(
    Placement(visible = true, transformation(origin = {-68, 80}, extent = {{-12, -12}, {12, 12}}, rotation = -90), iconTransformation(origin = {-2.22045e-16, 60}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
 
  Modelica.Blocks.Interfaces.RealInput parasities if external_parasities annotation(
    Placement(visible = true, transformation(origin = {82, 80}, extent = {{-12, -12}, {12, 12}}, rotation = -90), iconTransformation(origin = {20, 60}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  Modelica.Blocks.Interfaces.RealInput T_amb annotation(
    Placement(visible = true, transformation(origin = {10, 80}, extent = {{-12, -12}, {12, 12}}, rotation = -90), iconTransformation(origin = {-20, 60}, extent = {{-6, -6}, {6, 6}}, rotation = -90)));
  
  //******************************** Parameters -- for initalisation of the OTF object
  //******************************** CEA Power Block Parameters
  parameter SI.Power P_gross = 3e7;
  parameter SI.ThermodynamicTemperature T_in_ref_blk = 1243.27;
  parameter SI.Pressure p_high = 22707266.48;
  parameter Real PR = 2.98;
  parameter SI.TemperatureDifference pinch_PHX = 23.67;
  parameter SI.TemperatureDifference dTemp_HTF_PHX = 238.45;
  parameter Real load_base = 1;
  parameter SI.ThermodynamicTemperature T_amb_base = 39 + 273.15;
  
  //******************************** NREL SAM PB Parameters
  parameter Integer htf_choice = 50 "--------------------> 50 is user defined fluid properties";
  parameter Real dT_PHX_hot_approach = 20 "--------------------> [C/K] Temp. difference between hot HTF and TIT";
  parameter Real dT_PHX_cold_approach = 20 "---------------------> [C/K] Temp. difference between cold HTF and cold CO2 PHX inlet";
  parameter Real eta_isen_mc = 0.85 "----------------> main compressor isentropic efficiency";
  parameter Real eta_isen_rc = 0.85 "----------------> re-compressor isentropic efficiency";
  parameter Real eta_isen_t = 0.9 "-----------------> turbine isentropic efficiency";
  parameter Real dT_mc_approach = 6.0 "--------------------> [C/K] Temp. difference between main compressor CO2 inlet and ambient";  
  
  //********************************* On the fly and simulation configurations
  parameter String base_path = Modelica.Utilities.Files.loadResource(
                                                        "modelica://SolarTherm/Resources/Include") 
                                                        "Base path that points to which folder the C program is stored";
  parameter String SolarTherm_path = Modelica.Utilities.Files.loadResource(
                                                        "modelica://SolarTherm") "Base path of SolarTherm";
  parameter Integer which_PB_model = 1 "-----------------------> 0 is for CEA power block, 1 is for NREL-SAM power block";
  parameter String HTF_name = "CarboHSP";
  
  //********************************** On design efficiency values
  parameter Real eta_net_base = 0.005;
  parameter Real eta_Q_base = 5;
  
  parameter Integer inputsize = 3;
  parameter Integer outputsize = 2;
  parameter Real tolerance_kriging = 2.5e-3;
  parameter Real tolerance_ANN= 1.5e-3;
  
  //********************************** User choice which surrogate method
  parameter Integer which_surrogate = 1 "1 for Kriging, 2 for ANN"; 
  
  //********************************** Other essential parameters
  parameter SI.Temperature T_cold_set = 823.15;
  parameter SI.MassFlowRate m_HTF_des = 1000;
  parameter SI.Power Q_HX_des = 300e8;
  parameter Real f_fixed_load = 0.005;
  parameter Boolean external_parasities = true;
  parameter Boolean test_mode = true;
  parameter SI.Efficiency eta_motor = 0.95;
  parameter Real nu_min = 0.5;
  
  parameter MedRec.ThermodynamicState state_in_ref=MedRec.setState_pTX(1e5,T_in_ref_blk);
  parameter MedRec.ThermodynamicState state_out_ref=MedRec.setState_pTX(1e5,T_cold_set);
  parameter SI.SpecificEnthalpy h_in_ref=MedRec.specificEnthalpy(state_in_ref);
  parameter SI.SpecificEnthalpy h_out_ref=MedRec.specificEnthalpy(state_out_ref);

  //******************** Kriging
  Kriging_properties Kriging_variables = Kriging_properties(
                                         P_gross, T_in_ref_blk, p_high, PR, pinch_PHX, dTemp_HTF_PHX, load_base, T_amb_base,
                                         eta_net_base,  eta_Q_base, base_path,
                                         SolarTherm_path, inputsize, outputsize, tolerance_kriging, which_PB_model,
                                         htf_choice,dT_PHX_hot_approach, dT_PHX_cold_approach, eta_isen_mc, eta_isen_rc, 
                                         eta_isen_t, dT_mc_approach, HTF_name) if which_surrogate == 1;
  //******************** ANN PB
  parameter Integer index_0 = 0;
  ANN_properties session_PB = ANN_properties(
                                         P_gross, T_in_ref_blk, p_high, PR, pinch_PHX, dTemp_HTF_PHX, load_base, T_amb_base,
                                         eta_net_base, eta_Q_base, 
                                         index_0, base_path, SolarTherm_path, inputsize, outputsize, tolerance_ANN, 
                                         which_PB_model, htf_choice,dT_PHX_hot_approach, dT_PHX_cold_approach, eta_isen_mc,
                                         eta_isen_rc, eta_isen_t, dT_mc_approach, HTF_name) if which_surrogate == 2;
  
  //******************** ANN HX
  parameter Integer index_1 = 1;
  ANN_properties session_HX = ANN_properties(
                                         P_gross, T_in_ref_blk, p_high, PR, pinch_PHX, dTemp_HTF_PHX, load_base, T_amb_base,
                                         eta_net_base, eta_Q_base,
                                         index_1, base_path, SolarTherm_path, inputsize, outputsize, tolerance_ANN, 
                                         which_PB_model, htf_choice, dT_PHX_hot_approach, dT_PHX_cold_approach, eta_isen_mc,
                                         eta_isen_rc, eta_isen_t, dT_mc_approach, HTF_name) if which_surrogate == 2;
  
  //Results
  Real deviation_eta_net; 
  Real deviation_eta_Q;
  Real[inputsize] raw_input;
  //Boolean m_sup "Disconnect the production of electricity when the mass flow rate of the HTF to the HX is not enough";
  Real load "mass flow fraction of the exchanger compared to design condition";
  Integer state "1 means PB on, 0 means PB off"; 
  
  SI.Efficiency eta_net;
  SI.Efficiency eta_Q;
  SI.Efficiency eta_cycle_net;
  SI.Power Q_HX;
  SI.Power W_gross;
  SI.Energy E_net(final start = 0, fixed = true, displayUnit = "MW.h");
  
  SI.SpecificEnthalpy h_in;
  SI.SpecificEnthalpy h_out;
  SI.MassFlowRate mdot;
  
  initial equation
  state = 0;
  
  algorithm
  when mdot >= m_HTF_des * nu_min and state==0 then
    state := 1;
  elsewhen mdot< 0.999 * m_HTF_des*nu_min and state==1 then
    state := 0;
  end when;
  
  equation
  fluid_a.p = fluid_b.p;
  fluid_a.m_flow + fluid_b.m_flow = 0;
  fluid_a.h_outflow = 0;  
  
  mdot = fluid_a.m_flow;
  
  h_in = inStream(fluid_a.h_outflow);
  h_out = fluid_b.h_outflow;
    
  //when mdot >= m_HTF_des * nu_min then
  if state == 1 then
    if which_surrogate==1 then
      deviation_eta_net = OTF_Kriging_interpolate(Kriging_variables, raw_input, "eta_gross", "spherical"); 
      deviation_eta_Q = OTF_Kriging_interpolate(Kriging_variables, raw_input, "eta_Q", "spherical");
    else
      deviation_eta_net = OTF_ANN_predict(session_PB, raw_input, 0);
      deviation_eta_Q = OTF_ANN_predict(session_HX, raw_input, 1);
    end if; 
    eta_net = eta_net_base - deviation_eta_net;
    eta_Q = eta_Q_base - deviation_eta_Q;
    h_out = (fluid_a.m_flow*h_in - Q_HX) / fluid_a.m_flow;
    eta_cycle_net = W_net / Q_HX;
  else// mdot< 0.999 * m_HTF_des*nu_min then
    deviation_eta_net = 0;
    deviation_eta_Q = 0;
    eta_net=0;
    eta_Q=0;
    h_out=h_out_ref;
    eta_cycle_net=0;
  end if;
       
  load = mdot / m_HTF_des;

  
  Q_HX = eta_Q * Q_HX_des;
  W_gross = eta_net * Q_HX;
  
  if ramping then
    W_net = 0;
  else
    W_net = max(0,W_gross - (f_fixed_load*P_gross) - parasities);
  end if;

  der(E_net) = W_net;

  annotation(
    experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-06, Interval = 0.002),
    __OpenModelica_simulationFlags(lv = "LOG_STATS", outputFormat = "mat", s = "dassl"),
    Diagram);

end SurrogatesCO2PB_OTF;