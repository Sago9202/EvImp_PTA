** ------------------------------------------------------------------------------------------------------ **
** El Efecto del Programa Todos a Aprender: Evaluación de Impacto con Tratamiento Jerárquico Multivaluado **
** Do-file 1: Arreglo de datos y estadísticas descriptivas                                                **
** Escrito por: Santiago Gómez-Echeverry                                                                  **
** Última modificación: 30/07/2024                                                                        **
** -----------------------------------------------------------------------------------------------------  **
clear all
cap log close
set more off
graph set window fontface "Times New Roman"

global crudas "C:\Users\sagom\Dropbox\Papers\Impacto del Programa Todos a Aprender\3 - Datos\1 - Crudos"
global arregladas "C:\Users\sagom\Dropbox\Papers\Impacto del Programa Todos a Aprender\3 - Datos\2 - Arreglados"
global fnt "C:\Users\sagom\Dropbox\Papers\Impacto del Programa Todos a Aprender\4 - Figuras y tablas"

** ----------------------------- **
** (I) Arreglo de bases de datos **
** ----------------------------- ** 

* (i) Importar datos PTA *

cd "${crudas}\1 - Focalización PTA"
import excel using "Base final Focalización 2020 DCPBM_.xlsx", clear cellrange(A2:BJ20886) firstrow
gen PTA=1 if regexm(SedeacompañadaPTA, "SI")
replace PTA=0 if regexm(SedeacompañadaPTA, "no")
destring CODIGO_DANE_SEDE, replace
format CODIGO_DANE_SEDE CODIGO_DANE %12.0f
rename (Proyeccióndocentesacompañados Totaldetextosproyectadospara TransiciónPTA PrimeroPTA SegundoPTA TerceroPTA CuartoPTA QuintoPTA TotalmatriculaPTA CODIGO_DANE_SEDE CODIGO_DANE CODIGO_DANE_MUNICIPIO) (DocPTA TextPTA PTA_GT PTA_G1 PTA_G2 PTA_G3 PTA_G4 PTA_G5 PTA_TE coddane_sede coddane codmpio)
keep PTA DocPTA TextPTA PTA_G1 PTA_G2 PTA_G3 PTA_G4 PTA_G5 PTA_TE coddane coddane_sede codmpio
local pta_vars DocPTA TextPTA PTA_G1 PTA_G2 PTA_G3 PTA_G4 PTA_G5 PTA_TE
foreach var of local pta_vars{
  replace `var'=0 if PTA==1 & missing(`var')
}
label var coddane "Código DANE EE" 
label var coddane_sede "Código DANE sede"
save "${arregladas}\Foc_PTA", replace

* (ii) Importar datos C-600 *

* Docentes nivel educativo
cd "${crudas}\2 - C600"
use "Doc niv educ", replace
keep if NIVELENSE_ID==2
gen numdoc_n=SEDEDONI_CANTIDAD_HOMBRE+SEDEDONI_CANTIDAD_MUJER
rename (SEDE_CODIGO NIVELEDUCDOC_ID) (coddane_sede niveduc_doc)
collapse (sum) numdoc_n, by(coddane_sede niveduc_doc)
destring coddane_sede, replace
format coddane_sede %12.0f
forvalues i=1/14{
 local nive`i': label NIVELEDUCDOC_ID `i'
}
reshape wide numdoc_n, i(coddane_sede) j(niveduc_doc)
forvalues i=1/14{
 replace numdoc_n`i'=0 if missing(numdoc_n`i')
 label var numdoc_n`i' "`nive`i''"
}
ds numdoc_n*
egen numdoc_t=rowtotal(`r(varlist)')
label var numdoc_t "Número total de docentes - Básica primaria"
save "${arregladas}\Base_Maestra", replace

* Situación académica 2018 
use "Estado 2018", replace
format SEDE_CODIGO %12.0f
keep if regexm(NIVELENSE_NOMBRE, "primaria")
gen sit=substr(SITUACADE_NOMBRE,1,1)
gen nest_=JORNSITU_CANTIDAD_HOMBRE+JORNSITU_CANTIDAD_MUJER
rename (SEDE_CODIGO GRADO_CODIGO) (coddane_sede grado)
keep coddane_sede grado sit nest_
collapse (sum) nest_, by(coddane_sede grado sit) /* Agregamos las jornadas */
levelsof grado, local(grados)
levelsof sit, local(situa)
reshape wide nest_, i(coddane_sede grado) j(sit) string
reshape wide nest_*, i(coddane_sede) j(grado) string
foreach var of varlist nest_*{
 replace `var'=0 if missing(`var')
}
foreach grad of local grados{
 egen nest18`grad'=rowtotal(nest_A`grad' nest_D`grad' nest_R`grad' nest_T`grad')
 foreach sit of local situa{
  gen pest_`sit'18`grad'=nest_`sit'`grad'/nest18`grad'
  replace pest_`sit'18`grad'=0 if missing(pest_`sit'18`grad')
 }
 rename (nest_A`grad' nest_D`grad' nest_R`grad' nest_T`grad') (nest_A18`grad' nest_D18`grad' nest_R18`grad' nest_T18`grad')
}
forvalues i=1/5{
 rename (nest_A180`i' nest_D180`i' nest_R180`i' nest_T180`i' pest_A180`i' pest_D180`i' pest_R180`i' pest_T180`i' nest180`i') (nest_A18`i' nest_D18`i' nest_R18`i' nest_T18`i' pest_A18`i' pest_D18`i' pest_R18`i' pest_T18`i' nest18`i')
}
merge 1:m coddane_sede using "${arregladas}\Base_Maestra", gen(_merge_sit18)
save "${arregladas}\Base_Maestra", replace

* Situación académica 2019 
use "Estado 2019", replace
drop if NIVELENSE_NOMBRE=="Básica secundaria" | NIVELENSE_NOMBRE=="Media" | regexm(GRADO_NOMBRE,"ardín") | regexm(GRADO_NOMBRE, "Ciclo")
gen sit=substr(SITUACADE_NOMBRE,1,1)
gen nest_=JORNSITU_CANTIDAD_HOMBRE+JORNSITU_CANTIDAD_MUJER
rename (SEDE_CODIGO GRADO_CODIGO) (coddane_sede grado)
keep coddane_sede grado sit nest_
collapse (sum) nest_, by(coddane_sede grado sit) /* Agregamos las jornadas */
levelsof grado, local(grados)
levelsof sit, local(situa)
reshape wide nest_, i(coddane_sede grado) j(sit) string
reshape wide nest_*, i(coddane_sede) j(grado) string
foreach var of varlist nest_*{
 replace `var'=0 if missing(`var')
}
foreach grad of local grados{
 egen nest`grad'=rowtotal(nest_A`grad' nest_D`grad' nest_R`grad' nest_T`grad')
 foreach sit of local situa{
  gen pest_`sit'`grad'=nest_`sit'`grad'/nest`grad'
  replace pest_`sit'`grad'=0 if missing(pest_`sit'`grad')
 }
}

destring coddane_sede, replace
format coddane_sede %12.0f
merge 1:1 coddane_sede using "${arregladas}\Foc_PTA", gen(_merge_sit)
drop if _merge_sit==1
merge 1:1 coddane_sede using "${arregladas}\Base_Maestra", gen(_merge_sit19)
gen pDocPTA=DocPTA/numdoc_t
replace pDocPTA=. if missing(DocPTA) | missing(numdoc_t)
replace pDocPTA=. if pDocPTA>1 & !missing(pDocPTA)
egen std_DocPTA=std(pDocPTA), mean(1) std(1)
gen tPTA=TextPTA/(DocPTA+PTA_TE)
replace tPTA=. if missing(DocPTA) | missing(PTA_TE) | missing(TextPTA)
egen std_tPTA=std(tPTA), mean(1) std(1)
drop *TR*
forvalues i=1/5{
 gen pPTAG`i'=PTA_G`i'/nest0`i'
 replace pPTAG`i'=. if missing(nest0`i') | missing(PTA_G`i')
 replace pPTAG`i'=. if pPTAG`i'>1 & !missing(pPTAG`i')
 egen std_PTAG`i'=std(pPTAG`i'), mean(1) std(1)
 factor std_PTAG`i' std_DocPTA std_tPTA, pcf
 predict iPTAG`i'
 sum iPTAG`i'
 replace iPTAG`i'=100*(iPTAG`i' - `r(min)')/(`r(max)'-`r(min)')
 replace iPTAG`i'=100-iPTAG`i'
 paran std_PTAG`i' std_DocPTA std_tPTA, graph
 graph save "${fnt}\PA_iPTAG`i'", replace
 *gen iPTAG`i'= std_PTAG`i'+std_DocPTA+std_tPTA
 rename (nest_A0`i' nest_D0`i' nest_R0`i' nest_T0`i' pest_A0`i' pest_D0`i' pest_R0`i' pest_T0`i' nest0`i') (nest_A`i' nest_D`i' nest_R`i' nest_T`i' pest_A`i' pest_D`i' pest_R`i' pest_T`i' nest`i')
 rename (PTA_G`i' std_PTAG`i' iPTAG`i' pPTAG`i') (nPTA`i' std_PTA`i' iPTA`i' pPTA`i')
}
reshape long nest_A nest_A18 nest_D nest_D18 nest_R nest_R18 nest_T nest_T18 pest_A pest_D pest_R pest_T nest pest_A18 pest_D18 pest_R18 pest_T18 nest18 nPTA std_PTA iPTA pPTA, i(coddane_sede) j(grado)
replace pest_A=pest_A*100
replace pest_D=pest_D*100
replace pest_R=pest_R*100
replace pest_T=pest_T*100
replace pest_A18=pest_A18*100
replace pest_D18=pest_D18*100
replace pest_R18=pest_R18*100
replace pest_T18=pest_T18*100
label var nest_A "Número de estudiantes - Aprobados"
label var nest_D "Número de estudiantes - Desertores"
label var nest_R "Número de estudiantes - Reprobados"
label var nest_T "Número de estudiantes - Transferidos/Transladados"
label var pest_A "Porcentaje - Aprobados"
label var pest_D "Porcentaje - Desertores"
label var pest_R "Porcentaje - Reprobados"
label var pest_T "Porcentaje - Transferidos/Transladados"
label var DocPTA "Número de docentes PTA"
label var TextPTA "Textos proyectados PTA"
label var nPTA "Número de estudiantes - PTA"
label var PTA_TE "Número de estudiantes - PTA total"
label var pPTA "Porcentaje - PTA"
label var std_PTA "Estandarizada - Número de estudiantes en PTA"
label var std_DocPTA "Estandarizada - Número de docentes en PTA"
label var std_tPTA "Estandarziada - Número de textos PTA"
label var iPTA "Índice PTA"
save "${arregladas}\Base_Maestra", replace

* Caracter 
use "Carac Generales", replace 
labmask SECRETARIA_ID, val(SECRETARIA_NOMBRE)
rename (SEDE_CODIGO CODIGOINTERNODEPTO CODIGOINTERNOMUN AREA_ID SECTOR_ID SECRETARIA_ID) (coddane_sede cod_depto cod_mun area sector etc)
keep coddane_sede cod_depto cod_mun area sector etc
destring coddane_sede cod_depto cod_mun, replace
format coddane_sede %12.0f
merge 1:m coddane_sede using "${arregladas}\Base_Maestra", gen(_merge_carac)
save "${arregladas}\Base_Maestra", replace

* Rangos de edad - Grado 
use "Rangos de edad - Grado", replace
keep if NIVELENSE_ID==2
gen numest_redad=JORNTRA_CANTIDAD_HOMBRE+JORNTRA_CANTIDAD_MUJER
rename (SEDE_CODIGO GRADO_CODIGO RANGOEDAD_CODIGO JORNTRA_CANTIDAD_HOMBRE JORNTRA_CANTIDAD_MUJER) (coddane_sede grado rango_edad numest_h numest_m)
destring coddane_sede grado rango_edad, replace
format coddane_sede %12.0f
recode rango_edad (3=2)(4=3)(6=4)(8=5)
collapse (sum) numest_redad numest_h numest_m, by(coddane_sede grado rango_edad)
bys coddane_sede: egen numest_H=total(numest_h)
bys coddane_sede: egen numest_M=total(numest_m)
gen pest_M=numest_M/(numest_M+numest_H)
drop numest_h numest_m
reshape wide numest_redad, i(coddane_sede grado) j(rango_edad)
foreach var of varlist numest_redad*{
 replace `var'=0 if missing(`var')
}
label var numest_H "Número de estudiantes - Hombre"
label var numest_M "Número de estudiantes - Mujer"
label var pest_M "Porcentaje de estudiantes - Mujer"
label var numest_redad1 "Estudiantes - Rango de edad = 3-5"
label var numest_redad2 "Estudiantes - Rango de edad = 6-8"
label var numest_redad3 "Estudiantes - Rango de edad = 9-12"
label var numest_redad4 "Estudiantes - Rango de edad = 13-15"
label var numest_redad5 "Estudiantes - Rango de edad = 16 y más"
merge 1:1 coddane_sede grado using "${arregladas}\Base_Maestra", gen(_merge_redad)
save "${arregladas}\Base_Maestra", replace

* Personal
use "Personal", replace
gen numpers=SEDEPERO_CANTIDAD_HOMBRE+SEDEPERO_CANTIDAD_MUJER
rename (SEDE_CODIGO CATEGORIA_ID) (coddane_sede pers)
keep coddane_sede pers numpers
destring coddane_sede, replace
format coddane_sede %12.0f
reshape wide numpers, i(coddane_sede) j(pers)
foreach var of varlist numpers*{
 replace `var'=0 if missing(`var')
}
label var numpers1 "Directivo docente"
label var numpers2 "Docentes de aula"
label var numpers3 "Administrativos"
label var numpers4 "Docente de apoyo en aula"
label var numpers5 "Personal de apoyo en aula"
label var numpers6 "Docentes con labores administrativas"
merge 1:m coddane_sede using "${arregladas}\Base_Maestra", gen(_merge_pers)
save "${arregladas}\Base_Maestra", replace

* Intensidad horaria
use "Intensidad horaria", replace
keep if NIVELENSE_ID==2 & ESPECIALIDAD_ID==7 | NIVELENSE_ID==2 & ESPECIALIDAD_ID==5
keep if MODELOEDUC_CODIGO=="1"
rename (SEDE_CODIGO ESPECIALIDAD_ID JORNINTE_CANTIDAD_HORA) (coddane_sede area nhoras_a)
destring coddane_sede area, replace
format coddane_sede %12.0f
recode area (7=1) (5=2)
collapse (mean) nhoras_a, by(coddane_sede area)
reshape wide nhoras_a, i(coddane_sede) j(area)
label var nhoras_a1 "Horas - Matemáticas"
label var nhoras_a2 "Horas - Lenguaje"
merge 1:m coddane_sede using "${arregladas}\Base_Maestra", gen(_merge_horas)
save "${arregladas}\Base_Maestra", replace

* Etnia y sexo
use "Etnia y sexo", replace
keep if NIVELENSE_ID==2
gen numest_etn=JORNETN_CANTIDAD_HOMBRE+JORNETN_CANTIDAD_MUJER
rename (SEDE_CODIGO GRUPOETN_ID) (coddane_sede etn)
destring coddane_sede, replace
format coddane_sede %12.0f
collapse (sum)numest_etn, by(coddane_sede etn)
reshape wide numest_etn, i(coddane_sede) j(etn)
foreach var of varlist numest_etn*{
 replace `var'=0 if missing(`var')
}
label var numest_etn1 "Indígenas"
label var numest_etn2 "ROM (gitano)"
label var numest_etn3 "Negro, mulato, afrocolombiano o afrodescendiente"
label var numest_etn4 "Raizal"
label var numest_etn5 "Palenquero"
merge 1:m coddane_sede using "${arregladas}\Base_Maestra", gen(_merge_etn)
save "${arregladas}\Base_Maestra", replace

* (ii) Importar datos Saber 11° *

cd "${crudas}\3 - Saber 11°"

* Segundo semestre 2020
import delimited using "SB11_20202.txt", clear encoding(UTF8) delimiter("¬")
keep cole_cod_dane_sede punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_nse_establecimiento
rename (cole_cod_dane_sede punt_lectura_critica punt_matematicas punt_c_naturales punt_sociales_ciudadanas punt_ingles punt_global estu_nse_establecimiento) (coddane_sede punt_lc punt_m punt_cn punt_sc punt_i punt_g nse_ee)
format coddane_sede %12.0f
collapse (mean) punt_lc punt_m punt_cn punt_sc punt_i punt_g nse_ee, by(coddane_sede)
merge 1:m coddane_sede using "${arregladas}\Base_Maestra", gen(_merge_sb11)
drop if _merge_sb11==2
levelsof etc, local(etc)
foreach et of local etc{
  sum DocPTA if etc==`et'
  if (`r(mean)'==0){
  	drop if etc==`et'
  }
}
recode area (1=0) (2=1)
label define rur 0 "Urbana" 1 "Rural"
label values area rur
save "${arregladas}\Base_Maestra", replace

grc1leg "${fnt}\\PA_iPTAG1" "${fnt}\\PA_iPTAG2" "${fnt}\\PA_iPTAG3" "${fnt}\\PA_iPTAG4" "${fnt}\\PA_iPTAG5", ring(0) position(4) 
gr_edit legend.xoffset = -15
gr_edit legend.yoffset = 15
forval i=1/5{
 gr_edit .plotregion1.graph`i'.title.text = {}
 gr_edit .plotregion1.graph`i'.title.text.Arrpush "`i'°"
}
gr_edit .legend.plotregion1.label[1].text = {"Observado"}
gr_edit .legend.plotregion1.label[2].text = {"Ajustado"}
gr_edit .legend.plotregion1.label[3].text = {"Aleatorio"}
graph save "${fnt}\PA_iPTA", replace
!erase "${fnt}\\PA_iPTAG1.gph" "${fnt}\\PA_iPTAG2.gph" "${fnt}\\PA_iPTAG3.gph" "${fnt}\\PA_iPTAG4.gph" "${fnt}\\PA_iPTAG5.gph"

** ------------------------------ **
** (II) Estadísticas descriptivas **
** ------------------------------ ** 

* (i) Tabla con estadísticas descriptivas - Diferencias entre los que tienen PTA y los que no *

tab nse_ee, gen(nse_ee_n)
local descrp "pDocPTA tPTA pPTA iPTA pest_A pest_A18 pest_R pest_R18 pest_D pest_D18 area nse_ee_n1 nse_ee_n2 nse_ee_n3 nse_ee_n4 numdoc_n1 numdoc_n2 numdoc_n3 numdoc_n4 numdoc_n5 numdoc_n6 numdoc_n7 numdoc_n8 numdoc_n9 numdoc_n10 numdoc_n11 numdoc_n12 numdoc_n13 numdoc_n14 numpers1 numpers2 numpers3 numpers4 numpers5 nhoras_a1 nhoras_a2"

local nvars_descrp: word count `descrp'
matrix define Descr=J(`nvars_descrp',5,.)
matrix rownames Descr=`descrp'
forvalues i=1/`nvars_descrp'{
 local dvar: word `i' of `descrp'
 sum `dvar'
 matrix Descr[`i',1]=`r(mean)'
 matrix Descr[`i',2]=`r(sd)'
 matrix Descr[`i',3]=`r(min)'
 matrix Descr[`i',4]=`r(max)'
 matrix Descr[`i',5]=`r(N)'
}

frmttable using "${fnt}\Descriptivas.rtf", statmat(Descr) ctitles("Variables","Mean", "D.E.", "Mín", "Máx") varlabels replace

* (ii) Gráficas del índice de implementación del PTA *
histogram pDocPTA if PTA==1, kdensity kdenopts(lcolor(blue%80)) fraction bcolor(blue%40) title("(a) % docentes PTA") ytitle("Densidad") xtitle("Cantidad")  saving("${fnt}\DocPTA.gph", replace)
histogram tPTA if PTA==1, kdensity kdenopts(lcolor(red%80)) fraction bcolor(red%40) title("(b) Textos PTA por beneficiario") ytitle("Densidad") xtitle("Cantidad")  saving("${fnt}\TextPTA.gph", replace)
histogram pPTA if PTA==1, kdensity kdenopts(lcolor(orange%80)) fraction bcolor(orange%40) title("(c) % estudiantes PTA") ytitle("Densidad") xtitle("Porcentaje") saving("${fnt}\pPTA.gph", replace)
histogram iPTA if PTA==1, kdensity kdenopts(lcolor(green%80)) fraction bcolor(green%40) title("(d) Índice PTA") ytitle("Densidad") xtitle("Puntaje") saving("${fnt}\PTA.gph", replace)
graph combine "${fnt}\DocPTA.gph" "${fnt}\TextPTA.gph" "${fnt}\pPTA.gph" "${fnt}\PTA.gph", saving("${fnt}\iPTA.gp2", replace)
graph export "${fnt}\iPTA.png", replace
