# -*- coding: utf-8 -*-
"""
Created on Mon Oct  4 11:34:57 2021

@author: eamoros
"""

import pvlib
import pandas as pd
import numpy as np
import vocmax
import time
import datetime


def calculos(latitude, longitude,
                                     racking,
                                     surface_tilt, 
                                     surface_azimuth,
                                     axis_tilt, 
                                     axis_azimuth,
                                     max_angle, 
                                     gcr,
                                     albedo,
                                     a,
                                     b,
                                     deltaT,
                                     FD,
                                     cells_in_series,
                                     Voco,
                                     Bvoco,
                                     Isco,
                                     alpha_sc,
                                     efficiency,
                                     n_diode,
                                     bifaciality_factor,
                                     max_string_voltage,
                                     interval_in_hours,
                                     timedelta_in_year,
                                     termalmodel,
                                     u1,
                                     u0,
                                     tempsec,
                                     windsec
                                     ):
    data, _, elev, _ = pvlib.iotools.get_pvgis_tmy(lat = latitude, lon = longitude, outputformat = 'csv')
    data['time'] = data.index
    data
    
    
    weather = pd.DataFrame()
    weather['year'] = 2010
    weather['mont'] = data.time.dt.month
    weather['day'] = data.time.dt.day
    weather['hour'] = data.time.dt.hour
    weather['minute'] = data.time.dt.minute
    weather['dni'] = data['Gb(n)']
    weather['ghi'] = data['G(h)']
    weather['dhi'] = data['Gd(h)']
    weather['temp_air'] = data.T2m - tempsec
    weather['wind_speed'] = data.WS10m*windsec
    weather['year'] = 2010
    
    
    # Rename the weather data for input to PVLIB.
    if np.all([c in weather.columns for c in ['dni','dhi','ghi','temp_air',
                                          'wind_speed','year','month',
                                          'day','hour','minute']]):
    # All colmuns are propoerly labeled, skip any relabeling.
        pass
    else:
    # Try renaming from NSRDB default values.
        weather = weather.rename(
        columns={'DNI': 'dni',
                 'DHI': 'dhi',
                 'GHI': 'ghi',
                 'Temperature': 'temp_air',
                 'Wind Speed': 'wind_speed',
                 'Year':'year',
                 'Month':'month',
                 'Day':'day',
                 'Hour':'hour',
                 'Minute':'minute'})    
    
    location = pvlib.location.Location(latitude=latitude,
                                   longitude=longitude)
    
    # Ephemeris method is faster and gives very similar results.
    solar_position = location.get_solarposition(weather.index,
                                            method='ephemeris')
    
    # Get surface tilt and azimuth
    if racking == 'fixed_tilt':
    
        surface_tilt = surface_tilt
        surface_azimuth = surface_azimuth
    
    # idealized assumption
    else:
    
    # Avoid nan warnings by presetting unphysical zenith angles.
        solar_position['apparent_zenith'][
        solar_position['apparent_zenith'] > 90] = 90
    
    # Todo: Check appraent_zenith vs. zenith.
        single_axis_vals = pvlib.tracking.singleaxis(
            solar_position['apparent_zenith'],
            solar_position['azimuth'],
            axis_tilt=axis_tilt,
            axis_azimuth=axis_azimuth,
            max_angle=max_angle,
            backtrack=True,
            gcr=gcr
            )
        
        surface_tilt = surface_tilt
        surface_azimuth = surface_azimuth
    
    
    # Extraterrestrial radiation
    dni_extra = pvlib.irradiance.get_extra_radiation(solar_position.index)
    
    
    # perez model 
    total_irrad = pvlib.irradiance.get_total_irradiance(
        surface_tilt,
        surface_azimuth,
        solar_position['zenith'],
        solar_position['azimuth'],
        weather['dni'],
        weather['ghi'],
        weather['dhi'],
        model='perez',
        dni_extra = dni_extra,
        airmass = pvlib.atmosphere.get_relative_airmass(solar_position['zenith'], model='kastenyoung1989'),
        albedo= albedo)
    
    if racking == 'fixed_tilt':
        aoi = pvlib.irradiance.aoi(surface_tilt, 
                                   surface_azimuth,
                               solar_position['zenith'],
                               solar_position['azimuth'])
    else: 
        aoi = single_axis_vals['aoi']
        
    # aoi = single_axis_vals['aoi']
    
    airmass = location.get_airmass(solar_position=solar_position)
    
    # termalmodel
    
    if termalmodel == 'sandia':
    
        temps = pvlib.temperature.sapm_cell(poa_global = total_irrad['poa_global'],
                                    temp_air = weather['temp_air'],
                                     wind_speed = weather['wind_speed'],
                                     a = a, 
                                     b = b, 
                                     deltaT = deltaT)
        temps = pd.DataFrame(temps, columns =['temp_cell'])
    
    else:
        temps = pvlib.temperature.faiman(poa_global = total_irrad['poa_global'],
                                 temp_air = weather['temp_air'],  
                                 wind_speed = weather['wind_speed'],
                                u0 = u0, 
                                u1 = u1)
        temps = pd.DataFrame(temps, columns =['temp_cell'])

    
    
    spectral_loss = 1
    
    
    aoi_loss = pvlib.iam.ashrae(aoi,
                        b=0.04)
    
    effective_irradiance = vocmax.calculate_effective_irradiance(
        total_irrad['poa_direct'],
        total_irrad['poa_diffuse'],
        aoi_loss=aoi_loss,
        FD=FD
    )
    
    module = {
    # Number of cells in series in each module.
    'cells_in_series': cells_in_series,
    # Open circuit voltage at reference conditions, in Volts.
    'Voco': Voco,
    # Temperature coefficient of Voc, in Volt/C
    'Bvoco': Bvoco,
    # Short circuit current, in Amp
    'Isco':Isco,
    # Short circuit current temperature coefficient, in Amp/C
    'alpha_sc': alpha_sc,
    # Module efficiency, unitless
    'efficiency': efficiency,
    # Diode Ideality Factor, unitless
    'n_diode': n_diode,
    # Fracion of diffuse irradiance used by the module.
    'FD': FD,
    # Whether the module is bifacial
    'is_bifacial': True,
    # Ratio of backside to frontside efficiency for bifacial modules. Only used if 'is_bifacial'==True
    'bifaciality_factor': bifaciality_factor,
    # AOI loss model
    'aoi_model':'ashrae',
    # AOI loss model parameter.
    'ashrae_iam_param': 0.04
    }
    
    v_oc = vocmax.sapm_voc(effective_irradiance, 
                           temps['temp_cell'],
                               module)
    
    dffinal = weather.copy()
    dffinal['aoi'] = aoi
    # df['aoi_loss'] = aoi_loss
    dffinal['temp_cell'] = temps['temp_cell']
    dffinal['effective_irradiance'] = effective_irradiance
    dffinal['v_oc'] = v_oc
    
    return dffinal
    