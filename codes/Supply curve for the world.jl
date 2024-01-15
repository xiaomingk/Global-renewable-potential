#Renewable supply curve for the entire world under different discount rates
using Plots, CSV, DataFrames, Plots.PlotMeasures
S=CSV.read("supplyworld.csv",DataFrame);
SS=Matrix(S);
x=SS[:,1];
y=SS[:,2];
x1=SS[:,3];
y1=SS[:,4];
x2=SS[:,5];
y2=SS[:,6];

fig=plot(x, y,label = "Uniform discount rate", leg=:topleft, xlabel = "Renewable energy supply potential [PWh]", ylabel = "Levelized cost of energy [\$\$/MWh]", lw =2, xlims=(0, 400), ylims=(0,50), guidefontsize=12,tickfontsize=12, legendfontsize=10, size = (900, 500), left_margin = 10mm, right_margin = 10mm, bottom_margin = 10mm)
fig=plot!(x1, y1,label = "Country-specific discount rate", color="green",lw =2)
fig=plot!(x2, y2,label = "Energy demand",color="orange",lw =2)
savefig(fig,"Renewable supply for the world.png")
