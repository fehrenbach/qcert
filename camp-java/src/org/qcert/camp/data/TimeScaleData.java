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
package org.qcert.camp.data;


/**
 * Represents the time scale data constructor 
 */
public class TimeScaleData extends CampData {
	// TODO: if we want real time support we need to decide on representation
	private final Object timeScale;

	public TimeScaleData(Object timeScale) {
		this.timeScale = timeScale;
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.data.CampData#getKind()
	 */
	@Override
	public Kind getKind() {
		return Kind.dtime_scale;
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.CampAST#getOperands()
	 */
	@Override
	protected Object[] getOperands() {
		return new Object[] {timeScale};
	}

	/* (non-Javadoc)
	 * @see org.qcert.camp.CampAST#getTag()
	 */
	@Override
	protected String getTag() {
		return "dtime_scale";
	}

	/**
	 * @return the timeScale
	 */
	public Object getTimeScale() {
		return timeScale;
	}

	/* (non-Javadoc)
	 * @see java.lang.Object#toString()
	 */
	@Override
	public String toString() {
		return timeScale.toString();
	}
}
