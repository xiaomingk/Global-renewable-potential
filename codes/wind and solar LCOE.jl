using GlobalEnergyGIS, ImageTransformations, JLD
GE=GlobalEnergyGIS

solar_CF=GE.readraster("solarCF.tif")
wind_CF=GE.readraster("windCF.tif")
discountrate=GE.readraster("discountrate.tif")

windLCOE=zeros(36000,18000);
for i in 1:36000
    for j in 1:18000
        if discountrate[i,j]*wind_CF[i,j]>0
        windLCOE[i,j]=(discountrate[i,j]/(1-(1+discountrate[i,j])^(-25))*825+33)/8760/wind_CF[i,j]*1000
        end
    end
end
for i in 1:36000
    for j in 1:18000
        if windLCOE[i,j]>50
        windLCOE[i,j]=50
        end
    end
end
saveTIFF(windLCOE, "Wind_LCOE.tif", [-180.0, -90.0, 180.0, 90.0])

solarLCOE=zeros(36000,18000);
for i in 1:36000
    for j in 1:18000
        if discountrate[i,j]*solar_CF[i,j]>0
        solarLCOE[i,j]=(discountrate[i,j]/(1-(1+discountrate[i,j])^(-25))*323+8)/8760/solar_CF[i,j]*1000
        end
    end
end
for i in 1:36000
    for j in 1:18000
        if solarLCOE[i,j]>50
        solarLCOE[i,j]=50
        end
    end
end
saveTIFF(solarLCOE, "Solar_LCOE.tif", [-180.0, -90.0, 180.0, 90.0])
