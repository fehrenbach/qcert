/**
 * Copyright (C) 2016 Joshua Auerbach 
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.qcert.camp.pattern;

import java.util.List;

/**
 * Represents a CAMP Unary Operator pattern 
 */
public final class UnaryPattern extends CampPattern {
	private final UnaryOperator operator;
	private final Object parameter;

	/**
	 * Make new UnaryPattern with an operator that takes no parameters.
	 * Appropriateness of the operator is checked dynamically
	 */
	public UnaryPattern(UnaryOperator operator, CampPattern operand) {
		this(operator, null, operand);
	}

	/**
	 * Make new UnaryPattern with an operator that takes a String or List<String> parameter.
	 * Appropriateness of the operator and the operand type is checked dynamically
	 */
	public UnaryPattern(UnaryOperator operator, Object parameter, CampPattern operand) {
		super(operand);
		this.operator = operator;
		this.parameter = parameter;
		switch(operator.getParameterKind()) {
		case None:
			if (parameter != null)
				throw new IllegalArgumentException("No parameter with unary operator " + operator);
			return;
		case String:
			if (parameter instanceof String)
				return;
			throw new IllegalArgumentException("Scalar String parameter required with unary operator " + operator);
		case StringList:
			if (parameter instanceof List<?>) {
				List<?> lparm = (List<?>) parameter;
				if (lparm.size() > 0 && lparm.get(0) instanceof String)
					return;
			}
			throw new IllegalArgumentException("String list parameter required with unary operator " + operator);
		default:
			throw new IllegalStateException("Unexpected null ParameterKind");
		}
	}

	/**
	 * Subroutine for formatting String or List<String> parameters
	 */
	@SuppressWarnings("unchecked")
	private String formatParameter() {
		if (parameter == null)
			return "";
		if (parameter instanceof String)
			return " \"" + parameter + "\" ";
		StringBuilder bldr = new StringBuilder(" [");
		String delim = "";
		for (String s : (List<String>) parameter) {
			bldr.append(delim).append("\"").append(s).append("\"");
			delim = ", ";
		}
		return bldr.append("] ").toString();
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.pattern.CampPattern#getKind()
	 */
	@Override
	public Kind getKind() {
		return Kind.punop;
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.CampAST#getOperands()
	 */
	@Override
	protected Object[] getOperands() {
		return new Object[] {operator, getOperand()};
	}

	/**
	 * @return the operator
	 */
	public UnaryOperator getOperator() {
		return operator;
	}

	/**
	 * @return the List<String> parameter if any, else null
	 */
	@SuppressWarnings("unchecked")
	public List<String> getStringListParameter() {
		return parameter instanceof List<?> ? (List<String>) parameter : null;
	}

	/**
	 * @return the String parameter if any, else null
	 */
	public String getStringParameter() {
		return parameter instanceof String ? (String) parameter : null;
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.CampAST#getTag()
	 */
	@Override
	protected String getTag() {
		return "punop";
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		return operator + formatParameter() + "(" + getOperand() + ")";
	}
}
