/*
 * channels.h
 *
 *  Created on: May 3, 2020
 *      Author: johann
 */

#ifndef PY_ACF_TOOLBOX_CHANNELS_PRIVATE_CHANNELS_H_
#define PY_ACF_TOOLBOX_CHANNELS_PRIVATE_CHANNELS_H_

#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>

namespace py = pybind11;

py::array chnsCellSumMex(py::array data, unsigned int stepSize,
		unsigned int cellSize, unsigned int h, unsigned int w);
py::array imPadMex(const py::array A, const py::list pad,
		const std::string &type);

py::array rgbConvertMex(py::array I, int flag, bool single);

//TODO Can this be controlled from setup.py? Preferable with NDEBUG
//#define DEBUG

#ifndef DEBUG
#define dbg_py_print(...) ((void)0)
#else
template <typename... Args>
void dbg_py_print(const char *fmt, Args &&...args)
{
	py::print(
			py::str(fmt).format(std::forward<Args>(args)...));
}
#endif

#endif /* PY_ACF_TOOLBOX_CHANNELS_PRIVATE_CHANNELS_H_ */
