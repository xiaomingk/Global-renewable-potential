using GlobalEnergyGIS, StatsBase, JLD, DataFrames, CSV
GE=GlobalEnergyGIS

include ("Country level renewable supply input.jl")

function VREpotential(reg)

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


function hydro(reg)
hydrovars = GE.h5open(GE.in_datafolder("output","GISdata_hydro_$reg.mat"),"r")
existingcapac=read(hydrovars["existingcapac"])
existinginflowcf=read(hydrovars["existinginflowcf"])
Monthlyhour=[744;672;744;720;744;720;744;744;720;744;720;744]
totalinflow=existinginflowcf*Monthlyhour
hydroenergy=existingcapac*totalinflow
replace!(hydroenergy, NaN=>0)
return sum(hydroenergy)
end

function supply_pv(reg, plant_area, persons_per_km2, sminclasses, smaxclasses) #The reg(region) has to be defined with the GlobalEnergyGIS package first. The other parameters are defined in GlobalEnergyGIS.
		GISsolar(savetodisk=true, gisregion=reg, pvclasses_min=sminclasses, pvclasses_max=smaxclasses,
			plant_area=plant_area, plant_persons_per_km2=persons_per_km2)
			solarf = GE.h5open(GE.in_datafolder("output","GISdata_solar2018_$reg.mat"),"r")

			cfpva =read(solarf,"CFtime_pvplantA");
			cfpvb =read(solarf,"CFtime_pvplantB");
			cfr=read(solarf,"CFtime_pvrooftop");
			cfcsa =read(solarf,"CFtime_cspplantA");
			cfcsb=read(solarf,"CFtime_cspplantB");

			pva=read(solarf,"capacity_pvplantA");
			pvb=read(solarf,"capacity_pvplantB");
			pvr=read(solarf,"capacity_pvrooftop");
			csa=read(solarf,"capacity_cspplantA");
		    csb =read(solarf,"capacity_cspplantB");

	demand1 = JLD.load(GE.in_datafolder("output","SyntheticDemand_$(reg)_ssp2-26-2050_2018.jld"),"demand");
	demand=sum(demand1)/1000*1.75-hydro(reg);
	meanCF_a = mean_skipNaN_dim12(cfpva)
	meanCF_b = mean_skipNaN_dim12(cfpvb)
	meanCF_r = mean_skipNaN_dim12(cfr)
	meanCF_ca = mean_skipNaN_dim12(cfcsa)
	meanCF_cb = mean_skipNaN_dim12(cfcsb)
	capacity_a = sumdrop(pva, dims=1)
	capacity_b = sumdrop(pvb, dims=1)
	capacity_r = sumdrop(pvr, dims=1)
	capacity_ca = sumdrop(csa, dims=1)
	capacity_cb = sumdrop(csb, dims=1)
	# investcost = Dict(:pv => 323, :pvroof => 423, :CSP => 3746, :wind => 825, :offwind => 1500)
	# fixedcost = Dict(:pv => 8, :pvroof => 6, :CSP => 56, :wind => 33, :offwind => 55)
	# lifetime = Dict(:pv => 25, :CSP => 30, :wind => 25, :offwind => 25)
	wacc = 0.05 #You can define this value based on the country specific data
	sannualenergy_a = capacity_a .* meanCF_a .* 8760
	sannualenergy_b = capacity_b .* meanCF_b .* 8760
	sannualenergy_r = capacity_r .* meanCF_r .* 8760
	sannualenergy_ca = capacity_ca .* meanCF_ca .* 8760
	sannualenergy_cb = capacity_cb .* meanCF_cb .* 8760
	totalcost_a = capacity_a .* (323 * CRF(wacc, 25) + 8)
	totalcost_b = capacity_b .* ((323+200) * CRF(wacc, 25) + 8)
	totalcost_r = capacity_r .* (423 * CRF(wacc, 25) + 6)
	totalcost_ca = capacity_ca .* (3746 * CRF(wacc, 30) + 56) + capacity_ca .* meanCF_ca .* 8760 * 2.9 / 1000
	totalcost_cb = capacity_cb .* ((3746+200) * CRF(wacc, 30) + 56) + capacity_cb .* meanCF_ca .* 8760*2.9 / 1000
	slcoe_a = totalcost_a ./ sannualenergy_a .* 1000
	slcoe_b = totalcost_b ./ sannualenergy_b .* 1000
	slcoe_r = totalcost_r ./ sannualenergy_r .* 1000
	slcoe_ca = totalcost_ca ./ sannualenergy_ca .* 1000
	slcoe_cb = totalcost_cb ./ sannualenergy_cb .* 1000
	sdemandshare_a = sannualenergy_a / demand
	sdemandshare_b = sannualenergy_b / demand
	sdemandshare_r = sannualenergy_r / demand
	sdemandshare_ca = sannualenergy_ca / demand
	sdemandshare_cb = sannualenergy_cb / demand
	return sannualenergy_a, sannualenergy_b, sannualenergy_r, sannualenergy_ca, sannualenergy_cb, sdemandshare_a, sdemandshare_b, sdemandshare_r, sdemandshare_ca, sdemandshare_cb, slcoe_a, slcoe_b, slcoe_r, slcoe_ca, slcoe_cb
end

function supply_wind(reg, area_onshore, area_offshore, max_depth, persons_per_km2, wminclasses, wmaxclasses)
		GISwind(savetodisk=true, gisregion=reg, onshoreclasses_min=wminclasses, onshoreclasses_max=wmaxclasses,
			offshoreclasses_min=wminclasses, offshoreclasses_max=wmaxclasses,
			area_onshore=area_onshore, area_offshore=area_offshore, max_depth=max_depth, persons_per_km2=persons_per_km2)
			windf = GE.h5open(GE.in_datafolder("output","GISdata_wind2018_$reg.mat"),"r")
			cfa=read(windf,"CFtime_windonshoreA");
			cfb=read(windf,"CFtime_windonshoreB");
			cfoff=read(windf,"CFtime_windoffshore");
			wa=read(windf,"capacity_onshoreA");
			wb=read(windf,"capacity_onshoreB");
			woff=read(windf,"capacity_offshore");
	demand1 = JLD.load(GE.in_datafolder("output","SyntheticDemand_$(reg)_ssp2-26-2050_2018.jld"),"demand");
	demand=sum(demand1)/1000*1.75-hydro(reg);
	meanCF_a = mean_skipNaN_dim12(cfa)
	meanCF_b = mean_skipNaN_dim12(cfb)
	meanCF_off = mean_skipNaN_dim12(cfoff)
	capacity_a = sumdrop(wa, dims=1)
	capacity_b = sumdrop(wb, dims=1)
	capacity_off = sumdrop(woff, dims=1)
	wacc = 0.05 #You can define this value based on the country specific data
	totalcost_a = capacity_a .* (825 * CRF(wacc, 25) + 33)
	totalcost_b = capacity_b .* ((825+200) * CRF(wacc, 25) + 33)
	totalcost_off = capacity_off .* (1500 * CRF(wacc, 25) + 55)
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

#Calculate for solar
sannualenergy_a, sannualenergy_b, sannualenergy_r, sannualenergy_ca, sannualenergy_cb, sdemandshare_a, sdemandshare_b, sdemandshare_r, sdemandshare_ca, sdemandshare_cb, slcoe_a, slcoe_b, slcoe_r, slcoe_ca, slcoe_cb=supply_pv(reg,0.05,500,sminclasses,smaxclasses)
senergy=[sannualenergy_a;sannualenergy_b;sannualenergy_r;sannualenergy_ca;sannualenergy_cb]
sshare=[sdemandshare_a;sdemandshare_b;sdemandshare_r;sdemandshare_ca;sdemandshare_cb]
slcoe=[slcoe_a;slcoe_b;slcoe_r;slcoe_ca;slcoe_cb]
#Calculate for wind
wannualenergy_a, wannualenergy_b, wannualenergy_off, wdemandshare_a, wdemandshare_b, wdemandshare_off, wlcoe_a, wlcoe_b, wlcoe_off=supply_wind(reg, 0.1, 0.1, 60, 500, wminclasses, wmaxclasses)
wenergy=[wannualenergy_a;wannualenergy_b;wannualenergy_off]
wshare=[wdemandshare_a;wdemandshare_b;wdemandshare_off]
wlcoe=[wlcoe_a;wlcoe_b;wlcoe_off]
#Merge data for wind and solar
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
CSV.write("$(reg)_VRE.csv",vre)

ss = sortperm(slcoe)
sx = cumsum(sshare[ss])
sy = cumsum(senergy[ss])
Solar = DataFrame()
Solar.A = sort(slcoe)
Solar.B = sx
Solar.C = sy
Solar
CSV.write("$(reg)_solar.csv",Solar)

ws = sortperm(wlcoe)
wx = cumsum(wshare[ws])
wy = cumsum(wenergy[ws])
Wind = DataFrame()
Wind.A = sort(wlcoe)
Wind.B = wx
Wind.C = wy
Wind
CSV.write("$(reg)_wind.csv",Wind)

end

#Example to run the model

VREpotential("Italy")
