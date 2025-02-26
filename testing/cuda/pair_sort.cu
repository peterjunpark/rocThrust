#include <unittest/unittest.h>
#include <thrust/pair.h>
#include <thrust/sort.h>
#include <thrust/execution_policy.h>


#ifdef THRUST_TEST_DEVICE_SIDE
template<typename ExecutionPolicy, typename Iterator>
__global__
void stable_sort_kernel(ExecutionPolicy exec, Iterator first, Iterator last)
{
  thrust::stable_sort(exec, first, last);
}


struct make_pair_functor
{
  template <typename T1, typename T2>
  THRUST_HOST_DEVICE thrust::pair<T1, T2> operator()(const T1& x, const T2& y)
  {
    return thrust::make_pair(x,y);
  } // end operator()()
}; // end make_pair_functor


template<typename ExecutionPolicy>
void TestPairStableSortDevice(ExecutionPolicy exec)
{
  size_t n = 10000;
  typedef thrust::pair<int,int> P;

  thrust::host_vector<int>   h_p1 = unittest::random_integers<int>(n);
  thrust::host_vector<int>   h_p2 = unittest::random_integers<int>(n);
  thrust::host_vector<P>   h_pairs(n);

  // zip up pairs on the host
  thrust::transform(h_p1.begin(), h_p1.end(), h_p2.begin(), h_pairs.begin(), make_pair_functor());

  thrust::device_vector<P> d_pairs = h_pairs;

  stable_sort_kernel<<<1,1>>>(exec, d_pairs.begin(), d_pairs.end());
  cudaError_t const err = cudaDeviceSynchronize();
  ASSERT_EQUAL(cudaSuccess, err);

  // sort on the host
  thrust::stable_sort(h_pairs.begin(), h_pairs.end());

  ASSERT_EQUAL_QUIET(h_pairs, d_pairs);
};


void TestPairStableSortDeviceSeq()
{
  TestPairStableSortDevice(thrust::seq);
}
DECLARE_UNITTEST(TestPairStableSortDeviceSeq);


void TestPairStableSortDeviceDevice()
{
  TestPairStableSortDevice(thrust::device);
}
DECLARE_UNITTEST(TestPairStableSortDeviceDevice);
#endif

