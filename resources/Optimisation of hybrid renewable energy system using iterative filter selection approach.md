# Optimisation of hybrid renewable energy system using iterative filter selection approach
Link: https://ieeexplore-ieee-org.iclibezp1.cc.ic.ac.uk/stamp/stamp.jsp?tp=&arnumber=8049627 

## Notes

* A hybrid renewable system that yields **minimum total project cost** and **maximum reliability**, also **minimisation of unutilised surplus power**

* Current renewable energy sources: wind, solar, geothermal, biomass and hydropower. Main issue is reliability as highly dependent on nature and weather conditions.

* **Goal**: meet the required load demand.  
   **Min**: total cost, surplus power in the dump load  
   **Max**: system reliability
* Wind Turbine: Power = Output Power * (New Swept Area/Initial Swept Area)
* Photovoltaic Array: Power = Solar Irradiance * PV array area * Module Effeciency
* Fuzzy logic: the truth values of variables may be any real number between 0 and 1 both inclusive 
* Partical swarm: solves a problem by having a population of candidate solutions, here dubbed particles, and moving these particles around in the search-space according to simple mathematical formulae over the particle's position and velocity. https://en.wikipedia.org/wiki/Particle_swarm_optimization 
* Total Cost = initial cost of each component - salvage value of the components + number of components to be added * additional cost per unit of added components
* 1st filter: deal with critical objective. Maximum reliability and minimum dump load in this case.
* 2nd filter: deal with other objectives, i.e. Minimum cost. Divided solutions from 1st filter into 50%-50%. 50% are opimised for minimum cost, the other 50% contains non minimised cost but better reliability and dump load size (1st filter condition).
* 3rd filter: apply a fitness function (function of weighted values of cost and dump load size). Changing the weight of each variable affects the fitness function. In this case, large weight is assigned to dump load to apply **more** minimisation to dump load variable.
