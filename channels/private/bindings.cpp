#include <pybind11/pybind11.h>
#include <pybind11/numpy.h>
#include "channels.h"

namespace py = pybind11;

PYBIND11_MODULE(_channels, m) {
		m.doc() = R"pbdoc(
			Channels
			-----------------------
			
			.. currentmodule:: _channels
			
			.. autosummary::
			  :toctree: _generate
			
			  cellsum
		)pbdoc";

		m.def("chnsCellSumMex", &chnsCellSumMex, R"pbdoc(
			Compute cell sum.
		)pbdoc");
		m.def("imPadMex", &imPadMex, R"pbdoc(
			Pad an image along its four boundaries.
		)pbdoc");
		m.def("rgbConvertMex", &rgbConvertMex, R"pbdoc(
			Convert RGB image to other color spaces (highly optimized).
		)pbdoc");


		py::enum_<ColorSpace>(m, "ColorSpace")
		        .value("gray", ColorSpace::gray)
		        .value("rgb", ColorSpace::rgb)
				.value("luv", ColorSpace::luv)
				.value("hsv", ColorSpace::hsv)
				.value("orig", ColorSpace::orig)
				.value("yuv", ColorSpace::yuv)
				.value("yuv8", ColorSpace::yuv8);

#ifdef VERSION_INFO
       m.attr("__version__") = VERSION_INFO;
#else
       m.attr("__version__") = "dev";
#endif
}

