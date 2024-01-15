using Plots, CSV, DataFrames
#Function to plot the country supply courve for renewables (wind and solar)
function plotcountry(reg)
S=CSV.read("$(reg)_VRE.csv",DataFrame);
SS=Matrix(S);
y=SS[:,1];
x=SS[:,2];
fn=Plots.plot(x, y, primary=false, title ="$(reg)", titlefontsize=18, leg=:topleft, ylims=(0,200), xlabel = "Potential supply relative to demand", ylabel = "Renewable LCOE [\$\$/MWh]", lw = 2, lc = :red, framestyle=:axes,guidefontsize=14,tickfontsize=14)
savefig(fn,"$(reg).png")
end
#Example for Italy
plotcountry("Italy")
