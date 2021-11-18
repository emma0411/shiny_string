# -*- coding: utf-8 -*-
"""
Created on Fri Sep 24 09:01:57 2021

@author: eamoros
"""

import pvlib
import pandas as pd
import numpy as np
import vocmax
import time
import datetime

def simulate_system(latitude, longitude,
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
    
    df = dffinal.copy()
    ## calculate string size 
    
        # Calculate weather data safety factor using module Voc temperature coefficient
    Beta_Voco_fraction = np.abs(module['Bvoco'])/module['Voco']
    #weather_data_safety_factor = np.max([0, temperature_error*Beta_Voco_fraction])

    # Calculate propensity for extreme temperature fluctuations.
    extreme_cold_delta_T = vocmax.calculate_mean_yearly_min_temp(df.index,df['temp_air']) - df['temp_air'].min()

    # Compute safety factor for extreme cold temperatures
    extreme_cold_safety_factor = extreme_cold_delta_T*Beta_Voco_fraction


    voc_summary = pd.DataFrame(
        columns=['Conditions', 'v_oc', 'max_string_voltage', 'string_length',
                 'Cell Temperature','POA Irradiance','long_note'],
        index=['P99.5', 'Hist', 'Trad','Day'])

    mean_yearly_min_temp = vocmax.calculate_mean_yearly_min_temp(df.index,df['temp_air'])
    mean_yearly_min_day_temp = vocmax.calculate_mean_yearly_min_temp(df.index[df['ghi']>150],
                                              df['temp_air'][df['ghi']>150])

   # Calculate some standard voc values.
    voc_values = {
        'Hist': df['v_oc'].max(),
        'Trad': vocmax.calculate_voc(1000, mean_yearly_min_temp,
                                        module),
        'Day': vocmax.calculate_voc(1000, mean_yearly_min_day_temp,
                                        module),
        # 'Norm_P99.5':
        #     np.percentile(
        #         calculate_normal_voc(df['dni'],
        #                                        df['dhi'],
        #                                        df['temp_air'],
        #                                        module_parameters)
        #         , 99.5),
        'P99.5': df['v_oc'].quantile(0.995),
    }
    
    conditions = {
        'P99.5': 'P99.5 Voc',
        'Hist': 'Historical Maximum Voc',
        'Trad': 'Voc at 1 sun and mean yearly min ambient temperature',
        'Day': 'Voc at 1 sun and mean yearly minimum daytime (GHI>150 W/m2) temperature',
        # 'Norm_P99.5': 'P99.5 Voc assuming module normal to sun',
    }

    s_p99p5 = vocmax.get_temp_irradiance_for_voc_percentile(df,percentile=99.5)
    s_p100 = vocmax.get_temp_irradiance_for_voc_percentile(df,percentile=100,
                                                     cushion=0.0001)
    cell_temp = {
        'P99.5': s_p99p5['temp_cell'],
        'Day': mean_yearly_min_day_temp,
        'Trad': mean_yearly_min_temp,
        'Hist': s_p100['temp_cell']
    }

    poa_irradiance = {
        'P99.5': s_p99p5['effective_irradiance'],
        'Day': 1000,
        'Trad': 1000,
        'Hist': s_p100['effective_irradiance'],
    }



    voc_summary['v_oc'] = voc_summary.index.map(voc_values)
    voc_summary['Conditions'] = voc_summary.index.map(conditions)
    voc_summary['max_string_voltage'] = max_string_voltage
    voc_summary['POA Irradiance'] = voc_summary.index.map(poa_irradiance)
    voc_summary['Cell Temperature'] = voc_summary.index.map(cell_temp)


    voc_summary['string_length'] = voc_summary['v_oc'].map(
          lambda x: np.round(np.floor(max_string_voltage/x)))

    mean_yearly_min_temp = vocmax.calculate_mean_yearly_min_temp(df.index, df['temp_air'])

    long_note = {
        'P99.5': "99.5 Percentile Voc<br>" + \
                 "P99.5 Voc: {:.3f} V<br>".format(voc_values['P99.5']) +\
                 "Maximum String Length: {:.0f}<br>".format(voc_summary['string_length']['P99.5']) +\
                 "Recommended 690.7(A)(3) value for string length.",

        'Hist': 'Historical maximum Voc from {:.0f}-{:.0f}<br>'.format(df['year'][0], df['year'][-1]) +\
                'Hist Voc: {:.3f}<br>'.format(voc_values['Hist']) + \
                'Maximum String Length: {:.0f}<br>'.format(voc_summary['string_length']['Hist']) + \
                'Conservative value for string length.',

        'Day': 'Traditional daytime Voc, using 1 sun irradiance and<br>' +\
                'mean yearly minimum daytime (GHI>150 W/m^2) dry bulb temperature of {:.1f} C.<br>'.format(mean_yearly_min_day_temp) +\
                'Trad Voc: {:.3f} V<br>'.format(voc_values['Day']) +\
                'Maximum String Length:{:.0f}<br>'.format(voc_summary['string_length']['Trad']) +\
                'Recommended 690.7(A)(1) Value',

        'Trad': 'Traditional Voc, using 1 sun irradiance and<br>' +\
                'mean yearly minimum dry bulb temperature of {:.1f} C.<br>'.format(mean_yearly_min_temp) +\
                'Trad Voc: {:.3f}<br>'.format(voc_values['Trad']) +\
                'Maximum String Length: {:.0f}'.format(voc_summary['string_length']['Trad']),

        # 'Norm_P99.5': "Normal Voc, 99.5 percentile Voc value<br>".format(voc_values['Norm_P99.5']) +\
        #               "assuming array always oriented normal to sun.<br>" +\
        #               "Norm_P99.5 Voc: {:.3f}<br>".format(voc_values['Norm_P99.5']) +\
        #               "Maximum String Length: {:.0f}".format(voc_summary['string_length']['Norm_P99.5'])
    }
    
    short_note = {
        'P99.5': "Recommended 690.7(A)(3) value for string length.",

        'Hist': 'Conservative 690.7(A)(3) value for string length.',

        'Day':  'Traditional design using daytime temp (GHI>150 W/m^2)',

        'Trad': 'Traditional design',

        # 'Norm_P99.5': ""
        }

    voc_summary['long_note'] = voc_summary.index.map(long_note)
    voc_summary['short_note'] = voc_summary.index.map(short_note)
    voc_summary['v'] = voc_summary['v_oc']*voc_summary['string_length']


    
    # extra_parameters = calculate_extra_module_parameters(module_parameters)
    #voc_hist_x, voc_hist_y = vocmax.make_voc_histogram(df, info,number_bins=200)



# Save the summary csv to file.
#summary_file = 'out.csv'
#with open(summary_file,'w') as f:
#    f.write(summary)



    return voc_summary