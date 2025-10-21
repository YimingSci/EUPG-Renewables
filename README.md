# EuropeanPG-Renewables

This repository contains the data and code for the dynamical simulation of the continental European power-grid model presented in Ref. [1], used to assess the system's dynamical stability during the Iberian blackout of April 28, 2025. The generation mix and power flows have been adjusted to represent the high penetration of renewable energy sources—primarily wind and solar—present at the time of the blackout.



## Model Description

The European power-grid model incorporates **7,343** transmission lines, **3,809** buses, and **1,089** generators, including **470** renewable units representing available wind and solar installations. The grid topology is obtained from the published dataset in Ref. [2], while information on wind and solar installations is curated from Ref. [3]. The renewable generation data for Portugal, Spain, and France (collectively referred to as PSF region) reflect installations and capacities as of June 2025.

For power system analysis, we utilize widely adopted open-source tools, including the power flow solver MATPOWER [4] and the time-domain dynamic simulation framework described in Ref. [2]. Both tools are implemented in MATLAB, and we recommend using version R2024a for compatibility. See the reference below for more details.

<img width="2695" height="1480" alt="1" src="https://github.com/user-attachments/assets/791be8ea-0292-4004-998c-c2e377a3f349" />



**Fig. S1:** *Geographic distribution of generator/load nodes in the continental European power grid. The blue data points represent the locations of generator/load nodes reported in dataset [2], which was developed in 2018 and does not include wind or solar generators. The red data points show the geographic distribution of wind and solar generators in the PSF region, based on dataset [3].*




## Energy Mix

#### Conventional power generations
All power sources other than wind and solar are categorized as conventional generators. The types of conventional power generations involved are summarized in Table S1.
The parameters and geographical locations of these generators are based on dataset [2].

#### Wind and solar power generations
Based on the location and generation capacity data provided in Ref. [3], a total of 2,423 photovoltaic power stations and 32,644 wind turbines in the PSF region have been integrated into the European power grid model. Solar/wind generators with unreported generation capacity were turned off in the model.


<img width="3096" height="807" alt="图片5" src="https://github.com/user-attachments/assets/e7d3ff6c-a4a5-45a8-bb81-2b1bdd1418c8" />

**Table S1:** *List of the 13 types of power sources included in the European model, along with their corresponding abbreviations.*


Based on data provided by the transmission system operators (TSO), Fig. S2a-c shows the power generation profiles of Portugal [5], Spain [5], and France [6] on April 28, 2025. The blackout happened around 12:32 pm (UTC+01:00). To reflect this generation mix in the simulations, we pre-adjusted the generator outputs and power flows in the PSF region so that the modeled power mix in the three countries matches the conditions observed on that date, as shown in Fig. S2d-f.

<img width="2685" height="2090" alt="Energy_mix" src="https://github.com/user-attachments/assets/8b0e53cf-fe2f-4099-b6e8-032ab95a96f3" />

**Fig. S2:**
*(a,b,c) Generation mix of Portugal, Spain, and France on April 28, 2025 as reported by the TSO. Portugal and Spain exhibit similar structures, with solar and wind power dominating their generation portfolios. In contrast, nuclear power constitutes the dominant source in France.
(d,e,f) Adjusted generation mix used in the grid model for the corresponding countries.*


## Power Flow

Under the above power flow conditions, we use the MATPOWER toolbox to solve the power-flow equation (see below) and the compute the loading stress on the transmission network (Fig. S3). The color of each transmission line represents the magnitude of power flow, while the arrows indicate its direction. 

A notable observation is the reduced power transfer across the interconnections between the Iberian Peninsula and continental Europe prior to the blackout event, indicating a relatively light loading condition on these transmission corridors. To reflect this, we applied pre-adjustments to the power flow configuration, ensuring that the main power transfer was directed from Spain to France, with a net exchange of approximately 0.51 GW.



<img width="1000" alt="Power_flow" src="https://github.com/user-attachments/assets/21a0563d-f616-4538-84fe-50e3bf66792b" />

**Fig. S3:** *Distribution of power flows in the continental European grid.*






## Dynamical Analysis of the Power Grid

The dynamic behavior of the power-grid network is analyzed using the `Dynamic_analysis.m` script. The dynamics of generation nodes follows the second-order swing equation: 

<img width="4624" height="206" alt="eq1" src="https://github.com/user-attachments/assets/943001e3-17a8-46d1-a014-a000fdc249e2" />


where deltaidelta_i denotes the voltage phase angle of generator ii, MiM_i and DiD_i denotes its inertia and damping coefficients, Pi(0)P_{i(0)} is the mechanical power of node, and Pi(e)P_{i(e)} is the electric power of node. To reflect the low-inertia characteristics of wind and solar generators, a uniform inertia constant of 0.01 is assigned to them—approximately one-third of the minimum inertia constant among conventional power sources. The damping coefficient is uniformly set to 0.005. The imbalance between Pi(e)P_{i(e)} and  Pi(0)P_{i(0)} caused by the disturbance is the driving factor behind the onset of power system oscillations and potential instability. 

The dynamics of load nodes are described by first-order equations: 

<img width="4624" height="206" alt="eq2" src="https://github.com/user-attachments/assets/dd48b578-ccd7-4da8-83d6-a50927187426" />

Then, the power flow equations of the grid define the following algebraic constraints on the dynamical model:

<img width="4624" height="283" alt="eq3" src="https://github.com/user-attachments/assets/34e11223-66af-477d-8d27-61a070c284f0" />

where BijB_{ij}​ denotes the imaginary part of the admittance of the transmission line between nodes ii and jj, and ViV_i  represents the voltage magnitude at node ii.

Finally, we consider the following equation to quantify the contributions of a set of generators 𝒱gen𝒱_{gen} on the system inertia [8]:

<img width="4624" height="483" alt="eq4" src="https://github.com/user-attachments/assets/aa56d978-b0cf-4d30-b239-5db11e74240d" />


#### Disturbance

Our simulations consider six initial disturbances across the Iberian Peninsula, with their locations and magnitudes estimated from the official TSO report [7]. Details of the disturbances are provided in Table S1. The disturbances are applied to the electrical power injections at these six nodes, representing sudden power drops in the grid.

<img width="3095" height="806" alt="图片4" src="https://github.com/user-attachments/assets/864e42e9-dd0a-47b4-94cb-2000a0f2b612" />

**Table S2:** *Information on the locations and power loss of the initial disturbances. More than ten power loss events are grouped into six buses based on the disturbance locations, each named after a representative city. The Bus ID indicates the bus number of the simulated disturbance node, which can be cross-referenced with the bus numbers in `PSF_renewable.mat`*


#### Additional mitigation plan

In Ref. [1], we present two mitigation strategies to improve the system resilience against frequency fluctuations: one involves increasing the interconnection capacity between Spain and France, while the other focuses on increasing the synthetic inertia of renewable sources within the Iberian Peninsula. Here, we consider the combined implementation of both strategies and demonstrate that their joint effect leads to a significantly improved system response.

<img width="2892" height="1527" alt="图片8" src="https://github.com/user-attachments/assets/910b6fe4-21ec-4f7f-93ec-a54fbbf8b4c9" />


**Fig. S4:** *Frequency fluctuations across the Iberian Peninsula are even more suppressed when both mitigation plans are jointly applied.*


## Usage

- `PSF_renewable.mat` : Power grid data, provided in a `mpc` format compatible with MATPOWER [4], with power flows pre-adjusted to match the generation profiles shown in Figures 2d–f.
- `Dynamic_analysis.m` : Time-domain simulation code. This script includes fault initialization, parameter setup, and dynamic simulation procedures.
- `Cal_optimal_grad.m` : Gradient-based optimization code. This script performs steepest-descent path tracing with smoothing to compute the optimal investment trajectory.

Matpower 6.0 (https://matpower.org/download/) is required for the power flow calculation.

## Dependency

The following codes were used for simulations presented in Ref. [1]. If you use them
in any future work, please provide proper credit by citing Ref. [1].

- `NRsolver.m` : Solves power flow equations using the Newton-Raphson method.
- `Radau5.m`   : Integrates stiff differential equations using the Radau IIA method.

These scripts are included here with attribution for reproducibility and completeness.



## License

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

The full text of the GNU General Public License can be found in the file "LICENSE.txt".


## Reference

 1. Y. Wang, A. N. Montanari, and A. E. Motter, “Rethinking the Green Power Grid,” *submitted for publication*.
 2. M. Tyloo, L. Pagnier, and P. Jacquod, “The key player problem in complex oscillator networks and electric power grids: Resistance centralities identify local vulnerabilities,” *Science Advances*, vol. 5, no. 11, eaaw8359, 2019. [https://doi.org/10.1126/sciadv.aaw8359](https://doi.org/10.1126/sciadv.aaw8359)
 3. OpenInfraMap contributors, *OpenInfraMap – Infrastructure map of the world*, 2024. [https://openinframap.org](https://openinframap.org) (accessed Jul. 3, 2025)
 4. R. D. Zimmerman, C. E. Murillo-Sánchez, and R. J. Thomas, “MATPOWER: Steady-State Operations, Planning, and Analysis Tools for Power Systems Research and Education,” *IEEE Trans. Power Syst.*, vol. 26, no. 1, pp. 12–19, 2011.   [https://doi.org/10.1109/TPWRS.2010.2051168](https://doi.org/10.1109/TPWRS.2010.2051168)
 5.  ENTSO-E, "Iberian blackout on 28 April 2025", June 2025.   [https://www.entsoe.eu/publications/blackout/28-april-2025-iberian-blackout/](https://www.entsoe.eu/publications/blackout/28-april-2025-iberian-blackout/)
 6.  RTE France, "eco2mix – Power generation by energy source".   [https://www.rte-france.com/en/eco2mix/power-generation-energy-source](https://www.rte-france.com/en/eco2mix/power-generation-energy-source) (accessed Jul. 3, 2025)
 7.  Red Eléctrica de España, *Blackout in Spanish Peninsular Electrical System the 28th of April 2025*, June 2025.   [https://d1n1o4zeyfu21r.cloudfront.net/WEB\_Incident\_%2028A\_SpanishPeninsularElectricalSystem\_18june25.pdf](https://d1n1o4zeyfu21r.cloudfront.net/WEB_Incident_%2028A_SpanishPeninsularElectricalSystem_18june25.pdf)
 8.  ENTSO‑E, "Future system inertia – Nordic report".   [https://eepublicdownloads.entsoe.eu/clean-documents/Publications/SOC/Nordic/Nordic_report_Future_System_Inertia.pdf](https://eepublicdownloads.entsoe.eu/clean-documents/Publications/SOC/Nordic/Nordic_report_Future_System_Inertia.pdf) (accessed Jul. 15, 2025)

