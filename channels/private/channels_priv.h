/*
 * channels_priv.h
 *
 *  Created on: May 9, 2020
 *      Author: johann
 */

#ifndef CHANNELS_PRIVATE_CHANNELS_PRIV_H_
#define CHANNELS_PRIVATE_CHANNELS_PRIV_H_

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>

namespace py = pybind11;

inline void checkDimensions(ssize_t nDims)
{
	if (nDims != 2 && nDims != 3)
	{
		throw std::invalid_argument("Input should be 2D or 3D array.");
	}
}

inline void checkType(py::dtype id)
{
	if ((!id.is(py::dtype::of<float>()) && !id.is(py::dtype::of<double>())
			&& !id.is(py::dtype::of<uint8_t>())))
	{
		throw std::invalid_argument(
				"Input should of type single, double or uint8.");
	}
}

#endif /* CHANNELS_PRIVATE_CHANNELS_PRIV_H_ */
