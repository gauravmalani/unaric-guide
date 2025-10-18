/////////////////////////////////////////////////////////////////////////////////////////////////////
// UTILITY CLASSES, INCLUDING THOSE FOR EVALUATING FILTER CLAUSES 
//
// Prashant Kumar for Improved Apps
// August 2020
/////////////////////////////////////////////////////////////////////////////////////////////////////

public class Utilities {
    
    public class FilterEvaluator {
    
        private Boolean orJoin(String x, String y) { return evaluate(x) || evaluate(y); }
        private Boolean andJoin(String x, String y) { return evaluate(x) && evaluate(y); }
        private Boolean isSimpleExpression(String x) { return x == 'true' || x == 'false'; }
     
        
        // Evaluate an individual filter clause
        public boolean evaluateFilterClause(string val1,string op,string val2){
            boolean res;
            switch on op {
                when '>' {
                    res=val1>val2?True:False;
                }
                when '<' {
                    res=val1<val2?True:False;
                }
                when '>=' {
                    res=val1>=val2?True:False;
                }
                when '<=' {
                    res=val1<=val2?True:False;
                }
                when '=' {
                    if(val2=='null'){
                        res=string.isBlank(val1);
                    }
                    else{
                        res=val1==val2?True:False;
                    }
                }
                when '!=' {
                    if(val2=='null'){
                        res=string.isNotBlank(val1);
                    }
                    else{
                        res=val1!=val2?True:False;
                    }
                }
                when 'LIKE' {
                    if(val2.contains('%')){ //Check if there is a '%' sign in the string.
                        val2=val2.toUpperCase();//Change the string in uppercase
                        val1=val1.toUpperCase();
                        if(val2.startsWith('%')){
                            val2='[\\W\\w]*'+val2; // Replace '%' sign with regex expression 
                        }
                        if(val2.endsWith('%')){
                            val2=val2+'[\\W\\w]*';  
                        }
                        val2=val2.replaceAll('%','');
                        system.debug(' val2---- '+val2);
                        Pattern mypattern = Pattern.compile(val2);
                        Matcher matcher = mypattern.matcher(val1);
                        res=matcher.matches();
                    }
                    else{
                        res=val1==val2?True:False; 
                    }
                    
                }
            }
            return res;
        }

        
        // Parse a list of booleans into a filter logic string and return the evaluated result:
        // For example, given:
        //      values          = true, false, true
        //      expression      = 1 AND (2 OR 3)
        // ... return true (i.e., true AND (false OR true))
        
        public boolean evaluateFilterLogic (String filterLogic, Boolean[] values) {
            
            // Split expression into its individual parts
            String[] arguments = filterLogic.split(' ');
            
            for(String arg : arguments) {
                try {
                    // For each part of the expression, replace ordinals with 
                    // the relevant boolean by index number
                    Integer index = Integer.valueOf(arg.replaceAll('[^0-9]', ''));
                    filterLogic = filterLogic.replaceAll(String.valueOf(index), String.valueOf(values[index - 1]));
                    
                } catch(Exception e) {
                    // If the current clause of the expression is non-numeric,
                    // it will fall to this error trap and thus be left untouched
                }
            }
            return this.evaluate(filterLogic.toUpperCase());
        }
    
    
        // Given a string containing booleans, AND, OR plus brackets ONLY, return
        // the evaluated boolean result
        private Boolean evaluate(String expression) {
            
            expression = this.simplify(expression);
            
            if (!this.isSimpleExpression(expression)) {
                if (expression.contains('AND')) {
                    return this.andJoin(expression.substringBefore('AND'), expression.substringAfter('AND'));
                }
                
                if (expression.contains('OR')) {
                    return this.orJoin(expression.substringBefore('OR'), expression.substringAfter('OR'));
                }
                
                if (expression.startsWith('!')) return !this.evaluate(expression.substring(1));
            }
            return Boolean.valueOf(expression);
        }
    
    
        //
        private String simplify(String expression) {
            
            expression = expression.trim();
            
            if(!expression.contains('(')) return expression;
            
            while (expression.contains('(')) {
                string parentLogic = expression.substringAfter('(').substringBeforeLast(')');
                string result = this.evaluate(parentLogic) ? 'true' : 'false';
                expression = expression.replace('(' + parentLogic + ')', result);
            }
            return expression;
        }
    
    }
    
    
    
}