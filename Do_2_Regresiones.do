** ------------------------------------------------------------------------------------------------------ **
** El Efecto del Programa Todos a Aprender: Evaluación de Impacto con Tratamiento Jerárquico Multivaluado **
** Do-file 2: Ánalisis de regresión                                                                       **
** Escrito por: Santiago Gómez-Echeverry                                                                  **
** Última modificación: 30/07/2022                                                                        **
** -----------------------------------------------------------------------------------------------------  **
clear all
cap log close
set more off
graph set window fontface "Times New Roman"

global arregladas "C:\Users\sagom\Dropbox\Papers\Impacto del Programa Todos a Aprender\3 - Datos\2 - Arreglados"
global fnt "C:\Users\sagom\Dropbox\Papers\Impacto del Programa Todos a Aprender\4 - Figuras y tablas"

use "${arregladas}\Base_Maestra", replace
cap drop e_hat* sigma_hat* pr_t*

/* Variables independientes a nivel de establecimiento*/
global indep_x "i.area i.nse_ee  numdoc_n2 numdoc_n3 numdoc_n4 numdoc_n5 numdoc_n6 numdoc_n7 numdoc_n8 numdoc_n9 numdoc_n10 numdoc_n14  nhoras_a1 nhoras_a2 numpers1 numpers2 numpers3 numpers4 numpers5 numpers6 i.etc"

/* Variables independientes a nivel de grado*/

* - (i) Obtener el ICC - *
local res "A D R"
foreach var of local res{
 mixed pest_`var' || coddane_sede: 
 estat icc
 global ICC_`var'=`r(icc2)'
 global seICC_`var'=`r(se2)'
}


* - (ii) Estimación del puntaje de propensión - *
mixed iPTA || coddane_sede:
predict e_hat, resid
egen sigma_hat=sd(e_hat) 
gen pr_t=(1/(sqrt(2*_pi)*sigma_hat))*exp(-e_hat^(2)/(2*sigma_hat^2))

* 
mixed iPTA ${indep_x} || coddane_sede:
predict e_hatx, resid
egen sigma_hatx=sd(e_hat) 
gen pr_tx=(1/(sqrt(2*_pi)*sigma_hatx))*exp(-e_hatx^(2)/(2*sigma_hatx^2))
save "${arregladas}\Base_Maestra", replace

* - (iii) Balance - *

global indep_xn
foreach var of global indep_x{
  if (regexm("`var'","i.")){
   local catvar="`var'"
   local catvar: subinstr local catvar "i." "", all
   tab `catvar', gen(`catvar'_)
   ds `catvar'_*
   global indep_xn ${indep_xn} `r(varlist)'
  } 
  else {
   global indep_xn ${indep_xn} `var '
  }
}
macro dir

preserve
 clear
 set obs 1
 foreach var of global indep_xn{
  gen `var'=.
 }
 save "${arregladas}\Corr_indep_x", replace
restore

ds
foreach var of varlist `r(varlist)'{
 local l`var': variable label `var'
}

forvalues i=1/500{
 preserve
  gsample 2000 [w=(pr_t/pr_tx)]
  foreach var of global indep_xn{
   qui corr `var' iPTA
   local r_`var'=`r(rho)'
  }
  clear
  use "${arregladas}\Corr_indep_x", replace
  set obs `i'
  foreach var of global indep_xn{
   quietly replace `var'=`r_`var'' in `i'
  }
  save "${arregladas}\Corr_indep_x", replace
 restore
}

use "${arregladas}\Corr_indep_x", replace
ds
foreach var of varlist `r(varlist)'{
 label var `var' "`l`var''"
}
local vars="`r(varlist)'"
local nvars: word count `vars'
matrix define Bal=J(`nvars',4,.) 
matrix rownames Bal=`vars'
mat list Bal
forvalues i=1/`nvars'{
 local var: word `i' of `vars'
 ttest `var'==0.2
 matrix Bal[`i',1]=`r(mu_1)'
 matrix Bal[`i',2]=`r(sd_1)'
 matrix Bal[`i',3]=`r(p)'
 matrix Bal[`i',4]=`r(p_l)'
}
frmttable using "${fnt}\Balance.doc", statmat(Bal) varlabels ctitles("Variable", "Media", "E.S.", "p-valor, =", "p-valor, <") replace

* - (iv) Estimación del resultado - *
use "${arregladas}\Base_Maestra", replace
local panel "a b c"
local res "A D R"
local result "Aprobación Deserción Reprobación"
forvalues i=1/3{
 local varb: word `i' of `res'
 local lvar: word `i' of `result'
 local pan: word `i' of `panel'
 * Regresiones
 mixed pest_`varb' iPTA ${indep_x} pest_M pest_`varb'18 || coddane_sede: [pweight=(pr_t/pr_tx)], iterate(20)
 estimates store mix_`varb'
 margins, predict(xb) at(iPTA=(0(20)100))
 marginsplot, title("(`pan') `lvar'") ytitle("Predicción lineal")  saving("${fnt}\predict_`varb'.gph", replace)
 * Efectos heterogéneos
 mixed pest_`varb' iPTA ${indep_x} c.iPTA#i.area pest_M pest_`varb'18 || coddane_sede: [pweight=(pr_t/pr_tx)], iterate(20)
 estimates store mixi_`varb'
 margins, predict(xb) at(iPTA=(0(20)100)) over(area)
 marginsplot, title("(`pan') `lvar'") ytitle("Predicción lineal")  saving("${fnt}\interact_`varb'.gph", replace)
}

graph combine "${fnt}\predict_A.gph" "${fnt}\predict_D.gph" "${fnt}\predict_R.gph", r(1) ysize(1.000) xsize(2.500)
graph save "${fnt}\Predicciones", replace
graph export "${fnt}\Predicciones.png", replace
grc1leg "${fnt}\interact_A.gph" "${fnt}\interact_D.gph" "${fnt}\interact_R.gph", r(1) position(6) ysize(1.000) xsize(2.500) 
graph save "${fnt}\Interaccciones", replace
graph export "${fnt}\Interacciones.png", replace

esttab mix_A mix_D mix_R using "${fnt}\Regresiones.rtf", drop(*.etc) label aic(%10.3f) bic(%10.3f) ci compress b(%5.3f) ci(%5.3f) replace