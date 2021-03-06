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
package org.qcert.camp.rule;

import org.qcert.camp.pattern.CampPattern;

/**
 * Represnts rule_when in the Rule macro language 
 */
public final class WhenRule extends PatternRule {
	/**
	 * Make a WhenRule in functional form, given its pattern
	 */
	public WhenRule(CampPattern pattern) {
		super(pattern, null);
	}

	/**
	 * Make a new WhenRule from a functional WhenRule and an operand 
	 * @param functional the functional WhenRule
	 * @param operand the operand
	 */
	private WhenRule(WhenRule functional, CampRule operand) {
		super(functional.getPattern(), operand);
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.rule.CampRule#apply(org.qcert.camp.rule.CampRule)
	 */
	@Override
	public CampRule apply(CampRule operand) {
		return new WhenRule(this, operand);
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.rule.CampRule#getKind()
	 */
	@Override
	public Kind getKind() {
		return Kind.When;
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.CampAST#getTag()
	 */
	@Override
	protected String getTag() {
		return "rule_when";
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		return "rule_when (" + getPattern() + ")";
	}
}
