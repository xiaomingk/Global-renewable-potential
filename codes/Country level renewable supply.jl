using GlobalEnergyGIS, StatsBase, JLD, DataFrames, CSV
GE=GlobalEnergyGIS

CRF(r,T) = r / (1 - 1/(1+r)^T)
meandrop(x; dims=dims) = dropdims(mean(x, dims=dims), dims=dims)
sumdrop(x; dims=dims) = dropdims(sum(x, dims=dims), dims=dims)

function mean_skipNaN_dim12(xx)
	hours, regs, classes = size(xx)
	out = Vector{Float64}(undef,classes)
	for c = 1:classes
		hourtot = 0.0
		hourcount = 0
		for h = 1:hours
			regtot = 0.0
			regcount = 0
			for r = 1:regs
				x = xx[h,r,c]
				if !isnan(x)
					regtot += x
					regcount += 1
				end
			end
			if regcount != 0
				hourtot += regtot / regcount
				hourcount += 1
			end
		end
		out[c] = hourtot / hourcount
	end
	return out
end


#Define solar classes
sminclasses=[0.09	,
0.0925	,
0.095	,
0.0975	,
0.1	,
0.1025	,
0.105	,
0.1075	,
0.11	,
0.1125	,
0.115	,
0.1175	,
0.12	,
0.1225	,
0.125	,
0.1275	,
0.13	,
0.1325	,
0.135	,
0.1375	,
0.14	,
0.1425	,
0.145	,
0.1475	,
0.15	,
0.1525	,
0.155	,
0.1575	,
0.16	,
0.1625	,
0.165	,
0.1675	,
0.17	,
0.1725	,
0.175	,
0.1775	,
0.18	,
0.1825	,
0.185	,
0.1875	,
0.19	,
0.1925	,
0.195	,
0.1975	,
0.2	,
0.2025	,
0.205	,
0.2075	,
0.21	,
0.2125	,
0.215	,
0.2175	,
0.22	,
0.2225	,
0.225	,
0.2275	,
0.23	,
0.2325	,
0.235	,
0.2375	,
0.24	,
0.2425	,
0.245	,
0.2475	,
0.25	,
0.2525	,
0.255	,
0.2575	,
0.26	,
0.2625	,
0.265	,
0.2675	,
0.27	,
0.2725	,
0.275	,
0.2775	,
0.28	,
0.2825	,
0.285	,
0.2875	,
0.29	,
0.2925	,
0.295	,
0.2975	,
0.3	,
0.3025	,
0.305	,
0.3075	,
0.31	,
0.3125	,
0.315	,
0.3175	,
0.32	,
0.3225	,
0.325	,
0.3275	,
0.33	,
0.3325	,
0.335	,
0.3375	];

smaxclasses=[0.0925	,
0.095	,
0.0975	,
0.1	,
0.1025	,
0.105	,
0.1075	,
0.11	,
0.1125	,
0.115	,
0.1175	,
0.12	,
0.1225	,
0.125	,
0.1275	,
0.13	,
0.1325	,
0.135	,
0.1375	,
0.14	,
0.1425	,
0.145	,
0.1475	,
0.15	,
0.1525	,
0.155	,
0.1575	,
0.16	,
0.1625	,
0.165	,
0.1675	,
0.17	,
0.1725	,
0.175	,
0.1775	,
0.18	,
0.1825	,
0.185	,
0.1875	,
0.19	,
0.1925	,
0.195	,
0.1975	,
0.2	,
0.2025	,
0.205	,
0.2075	,
0.21	,
0.2125	,
0.215	,
0.2175	,
0.22	,
0.2225	,
0.225	,
0.2275	,
0.23	,
0.2325	,
0.235	,
0.2375	,
0.24	,
0.2425	,
0.245	,
0.2475	,
0.25	,
0.2525	,
0.255	,
0.2575	,
0.26	,
0.2625	,
0.265	,
0.2675	,
0.27	,
0.2725	,
0.275	,
0.2775	,
0.28	,
0.2825	,
0.285	,
0.2875	,
0.29	,
0.2925	,
0.295	,
0.2975	,
0.3	,
0.3025	,
0.305	,
0.3075	,
0.31	,
0.3125	,
0.315	,
0.3175	,
0.32	,
0.3225	,
0.325	,
0.3275	,
0.33	,
0.3325	,
0.335	,
0.3375	,
1	];

function supply_pv(reg, plant_area, persons_per_km2, sminclasses, smaxclasses) #The reg(region) has to be defined with the GlobalEnergyGIS package first. The other parameters are defined in GlobalEnergyGIS.
		GISsolar(savetodisk=true, gisregion=reg, pvclasses_min=sminclasses, pvclasses_max=smaxclasses,
			plant_area=plant_area, plant_persons_per_km2=persons_per_km2)
			solarf = GE.h5open(GE.in_datafolder("output","GISdata_solar2018_$reg.mat"),"r")
			cfr=read(solarf,"CFtime_pvrooftop");
			cfpva =read(solarf,"CFtime_pvplantA");
			cfpvb =read(solarf,"CFtime_pvplantB");
			cfcsa =read(solarf,"CFtime_cspplantA");
			cfcsb=read(solarf,"CFtime_cspplantB");
			pvr=read(solarf,"capacity_pvrooftop");
			pva=read(solarf,"capacity_pvplantA");
			pvb=read(solarf,"capacity_pvplantB");
			csa=read(solarf,"capacity_cspplantA");
		    csb =read(solarf,"capacity_cspplantB");
	demand1 = JLD.load(GE.in_datafolder("output","SyntheticDemand_$(reg)_ssp2-26-2050_2018.jld"),"demand");
	demand=sum(demand1)/1000;
	meanCF_a = mean_skipNaN_dim12(cfpva)
	meanCF_b = mean_skipNaN_dim12(cfpvb)
	meanCF_r = mean_skipNaN_dim12(cfr)
	capacity_a = sumdrop(pva, dims=1)
	capacity_b = sumdrop(pvb, dims=1)
	capacity_r = sumdrop(pvr, dims=1)
	# investcost = Dict(:pv => 323, :pvroof => 423, :wind => 825, :offwind => 2000)
	# fixedcost = Dict(:pv => 8, :pvroof => 6, :wind => 33, :offwind => 55)
	# lifetime = Dict(:pv => 25, :wind => 25, :offwind => 25)
	wacc = 0.05#You can define this value based on the country specific data
	totalcost_a = capacity_a .* (323 * CRF(wacc, 25) + 8)
	totalcost_b = capacity_b .* ((323+200) * CRF(wacc, 25) + 8)
	totalcost_r = capacity_r .* (423 * CRF(wacc, 25) + 6)
	sannualenergy_a = capacity_a .* meanCF_a .* 8760
	sannualenergy_b = capacity_b .* meanCF_b .* 8760
	sannualenergy_r = capacity_r .* meanCF_r .* 8760
	slcoe_a = totalcost_a ./ sannualenergy_a .* 1000
	slcoe_b = totalcost_b ./ sannualenergy_b .* 1000
	slcoe_r = totalcost_r ./ sannualenergy_r .* 1000
	sdemandshare_a = sannualenergy_a / demand
	sdemandshare_b = sannualenergy_b / demand
	sdemandshare_r = sannualenergy_r / demand
	return sannualenergy_a, sannualenergy_b, sannualenergy_r, sdemandshare_a, sdemandshare_b, sdemandshare_r, slcoe_a, slcoe_b, slcoe_r
end

#Define wind classes
wminclasses=[2	,
2.325	,
2.65	,
2.975	,
3.3	,
3.625	,
3.95	,
4.275	,
4.6	,
4.925	,
5.25	,
5.575	,
5.9	,
6.225	,
6.55	,
6.875	,
7.2	,
7.525	,
7.85	,
8.175	,
8.5	,
8.825	,
9.15	,
9.475	,
9.8	,
10.125	,
10.45	,
10.775	,
11.1	,
11.425	,
11.75	,
12.075	,
12.4	,
12.725	,
13.05	,
13.375	,
13.7	,
14.025	,
14.35	,
14.675	,
15	,
15.325	,
15.65	,
15.975	,
16.3	,
16.625	,
16.95	,
17.275	,
17.6	,
17.925	,
18.25	,
18.575	,
18.9	,
19.225	,
19.55	,
19.875	,
20.2	,
20.525	,
20.85	,
21.175	,
21.5	,
21.825	,
22.15	,
22.475	,
22.8	,
23.125	,
23.45	,
23.775	,
24.1	,
24.425	,
24.75	,
25.075	,
25.4	,
25.725	,
26.05	,
26.375	,
26.7	,
27.025	,
27.35	,
27.675	,
28	,
28.325	,
28.65	,
28.975	,
29.3	,
29.625	,
29.95	,
30.275	,
30.6	,
30.925	,
31.25	,
31.575	,
31.9	,
32.225	,
32.55	,
32.875	,
33.2	,
33.525	,
33.85	,
34.175	];


wmaxclasses=[2.325	,
2.65	,
2.975	,
3.3	,
3.625	,
3.95	,
4.275	,
4.6	,
4.925	,
5.25	,
5.575	,
5.9	,
6.225	,
6.55	,
6.875	,
7.2	,
7.525	,
7.85	,
8.175	,
8.5	,
8.825	,
9.15	,
9.475	,
9.8	,
10.125	,
10.45	,
10.775	,
11.1	,
11.425	,
11.75	,
12.075	,
12.4	,
12.725	,
13.05	,
13.375	,
13.7	,
14.025	,
14.35	,
14.675	,
15	,
15.325	,
15.65	,
15.975	,
16.3	,
16.625	,
16.95	,
17.275	,
17.6	,
17.925	,
18.25	,
18.575	,
18.9	,
19.225	,
19.55	,
19.875	,
20.2	,
20.525	,
20.85	,
21.175	,
21.5	,
21.825	,
22.15	,
22.475	,
22.8	,
23.125	,
23.45	,
23.775	,
24.1	,
24.425	,
24.75	,
25.075	,
25.4	,
25.725	,
26.05	,
26.375	,
26.7	,
27.025	,
27.35	,
27.675	,
28	,
28.325	,
28.65	,
28.975	,
29.3	,
29.625	,
29.95	,
30.275	,
30.6	,
30.925	,
31.25	,
31.575	,
31.9	,
32.225	,
32.55	,
32.875	,
33.2	,
33.525	,
33.85	,
34.175	,
100	];


function supply_wind(reg, area_onshore, persons_per_km2, wminclasses, wmaxclasses)
		GISwind(savetodisk=true, gisregion=reg, onshoreclasses_min=wminclasses, onshoreclasses_max=wmaxclasses,
			offshoreclasses_min=wminclasses, offshoreclasses_max=wmaxclasses,
			area_onshore=area_onshore, persons_per_km2=persons_per_km2)
			windf = GE.h5open(GE.in_datafolder("output","GISdata_wind2018_$reg.mat"),"r")
			cfa=read(windf,"CFtime_windonshoreA");
			cfb=read(windf,"CFtime_windonshoreB");
			cfoff=read(windf,"CFtime_windoffshore");
			wa=read(windf,"capacity_onshoreA");
			wb=read(windf,"capacity_onshoreB");
			woff=read(windf,"capacity_offshore");
	demand1 = JLD.load(GE.in_datafolder("output","SyntheticDemand_$(reg)_ssp2-26-2050_2018.jld"),"demand");
	demand=sum(demand1)/1000;
	meanCF_a = mean_skipNaN_dim12(cfa)
	meanCF_b = mean_skipNaN_dim12(cfb)
	meanCF_off = mean_skipNaN_dim12(cfoff)
	capacity_a = sumdrop(wa, dims=1)
	capacity_b = sumdrop(wb, dims=1)
	capacity_off = sumdrop(woff, dims=1)
	wacc = 0.05
	totalcost_a = capacity_a .* (825 * CRF(wacc, 25) + 33)
	totalcost_b = capacity_b .* ((825+200) * CRF(wacc, 25) + 33)
	totalcost_off = capacity_off .* (2000 * CRF(wacc, 25) + 55)
	wannualenergy_a = capacity_a .* meanCF_a .* 8760
	wannualenergy_b = capacity_b .* meanCF_b .* 8760
	wannualenergy_off = capacity_off .* meanCF_off .* 8760
	wlcoe_a = totalcost_a ./ wannualenergy_a .* 1000
	wlcoe_b = totalcost_b ./ wannualenergy_b .* 1000
	wlcoe_off = totalcost_off ./ wannualenergy_off .* 1000
	wdemandshare_a = wannualenergy_a / demand
	wdemandshare_b = wannualenergy_b / demand
	wdemandshare_off = wannualenergy_off / demand
	return wannualenergy_a, wannualenergy_b, wannualenergy_off, wdemandshare_a, wdemandshare_b, wdemandshare_off, wlcoe_a, wlcoe_b, wlcoe_off
end

#Example for Italy
sannualenergy_a, sannualenergy_b, sannualenergy_r, sdemandshare_a, sdemandshare_b, sdemandshare_r, slcoe_a, slcoe_b, slcoe_r=supply_pv("Italy",0.05,150,sminclasses,smaxclasses)
senergy=[sannualenergy_a; sannualenergy_b; sannualenergy_r]
sshare=[sdemandshare_a;sdemandshare_b;sdemandshare_r]
slcoe=[slcoe_a;slcoe_b;slcoe_r]
wannualenergy_a, wannualenergy_b, wannualenergy_off, wdemandshare_a, wdemandshare_b, wdemandshare_off, wlcoe_a, wlcoe_b, wlcoe_off=supply_wind("Italy", 0.1, 150, wminclasses, wmaxclasses)
#Offshore wind is not considered in the output data
wenergy=[wannualenergy_a; wannualenergy_b]
wshare=[wdemandshare_a;wdemandshare_b]
wlcoe=[wlcoe_a;wlcoe_b]

energy=[senergy;wenergy]
share=[sshare;wshare]
lcoe=[slcoe;wlcoe]

s = sortperm(lcoe)
x = cumsum(share[s])
y = cumsum(energy[s])
vre = DataFrame()
vre.A = sort(lcoe)
vre.B = x
vre.C = y
vre
CSV.write("Italy_VRE.csv",vre)

ss = sortperm(slcoe)
sx = cumsum(sshare[ss])
sy = cumsum(senergy[ss])
Solar = DataFrame()
Solar.A = sort(slcoe)
Solar.B = sx
Solar.C = sy
Solar
CSV.write("Italy_solar.csv",Solar)

ws = sortperm(wlcoe)
wx = cumsum(wshare[ws])
wy = cumsum(wenergy[ws])
Wind = DataFrame()
Wind.A = sort(wlcoe)
Wind.B = wx
Wind.C = wy
Wind
CSV.write("Italy_wind.csv",Wind)
