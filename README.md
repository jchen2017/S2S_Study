# S2S_Study
STATA code for statistical analysis for the S2S study (manuscript accepted by JAMA Network)

***************************************

copyright 2022 Jinying Chen, UMass Chan Medical School

Licensed under the MIT License (the "License");
you may not use this file except in compliance with the License.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 
***************************************

To run the code:
 
1. Setting input data directory

 replace [[input dir]] in the definition of the global macro datadir in the file analyze_s2s_data.do
 (around line 39) by the directory that holds the input file

2. Setting input data file

 replace [[data file]] in the definition of the global macro allsurveys in the file analyze_s2s_data.do
 (around line 40) by the input file (in Stata data format) 

3. Program running order

(1) prepare_data -> table_1, table_2, table_3

(2) identify_unbalance_mi -> generate_mi_4grp -> table_2_mi, table_3_mi


