/*******************************************************************************
* Copyright 2023 Intel Corporation
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*******************************************************************************/

#include "oneapi/dal/algo/covariance/backend/gpu/finalize_compute_kernel.hpp"
#include "oneapi/dal/algo/covariance/backend/gpu/misc.hpp"

#include "oneapi/dal/backend/primitives/lapack.hpp"
#include "oneapi/dal/backend/primitives/reduction.hpp"
#include "oneapi/dal/backend/primitives/stat.hpp"
#include "oneapi/dal/backend/primitives/utils.hpp"

#include "oneapi/dal/table/row_accessor.hpp"

namespace oneapi::dal::covariance::backend {

namespace bk = dal::backend;
namespace pr = oneapi::dal::backend::primitives;
using alloc = sycl::usm::alloc;

using bk::context_gpu;
using task_t = task::compute;
using input_t = partial_compute_result<task_t>;
using result_t = compute_result<task_t>;
using descriptor_t = detail::descriptor_base<task_t>;

template <typename Float, typename Task>
static compute_result<Task> finalize_compute(const context_gpu& ctx,
                                             const descriptor_t& desc,
                                             const partial_compute_result<Task>& input) {
    auto& q = ctx.get_queue();

    const std::int64_t column_count = input.get_partial_crossproduct().get_column_count();
    ONEDAL_ASSERT(column_count > 0);

    dal::detail::check_mul_overflow(column_count, column_count);

    auto bias = desc.get_bias();
    auto result = compute_result<task_t>{}.set_result_options(desc.get_result_options());

    const auto nobs_host = pr::table2ndarray<Float>(q, input.get_partial_n_rows());
    auto rows_count_global = nobs_host.get_data()[0];
    ONEDAL_ASSERT(rows_count_global > 0);

    const auto sums =
        pr::table2ndarray_1d<Float>(q, input.get_partial_sum(), sycl::usm::alloc::device);
    const auto xtx =
        pr::table2ndarray<Float>(q, input.get_partial_crossproduct(), sycl::usm::alloc::device);

    if (desc.get_result_options().test(result_options::cov_matrix)) {
        auto [cov, cov_event] = compute_covariance(q, rows_count_global, xtx, sums, bias);
        result.set_cov_matrix(
            (homogen_table::wrap(cov.flatten(q, { cov_event }), column_count, column_count)));
    }
    if (desc.get_result_options().test(result_options::cor_matrix)) {
        auto [corr, corr_event] = compute_correlation(q, rows_count_global, xtx, sums);
        result.set_cor_matrix(
            (homogen_table::wrap(corr.flatten(q, { corr_event }), column_count, column_count)));
    }
    if (desc.get_result_options().test(result_options::means)) {
        auto [means, means_event] = compute_means(q, sums, rows_count_global);
        result.set_means(homogen_table::wrap(means.flatten(q, { means_event }), 1, column_count));
    }
    return result;
}

template <typename Float>
struct finalize_compute_kernel_gpu<Float, method::dense, task_t> {
    result_t operator()(const context_gpu& ctx,
                        const descriptor_t& desc,
                        const input_t& input) const {
        return finalize_compute<Float, task_t>(ctx, desc, input);
    }
};

template struct finalize_compute_kernel_gpu<float, method::dense, task_t>;
template struct finalize_compute_kernel_gpu<double, method::dense, task_t>;

} // namespace oneapi::dal::covariance::backend
