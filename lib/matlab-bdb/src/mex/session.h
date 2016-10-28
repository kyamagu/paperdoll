/// MEX function session helper library.
///
/// Kota Yamaguchi 2013 <kyamagu@cs.stonybrook.edu>

#ifndef __MEX_SESSION_H__
#define __MEX_SESSION_H__

#include <map>
#include <mex.h>

namespace mex {

/// Session keeper useful to make a stateful API.
template <typename T>
class Session {
public:
  /// Create an instance.
  static int create(T** instance);
  /// Destroy an instance.
  static void destroy(int id);
  /// Retrieve an instance. When special id=0 is specified, it returns default
  /// instance or NULL if there is no instance.
  static T* get(int id);
  /// Get session instances.
  static const std::map<int, T>& get_const_instances();

private:
  /// Constructor prohibited.
  Session() {}
  ~Session() {}
  /// Instance storage.
  static std::map<int, T>* get_instances();
};

template <typename T>
int Session<T>::create(T** instance) {
  std::map<int, T>* instances = get_instances();
  int id = (instances->empty()) ? 0 : instances->rbegin()->first;
  T* instance_ptr = &(*instances)[++id];
  if (instance != NULL)
    *instance = instance_ptr;
  return id;
}

template <typename T>
void Session<T>::destroy(int id) {
  std::map<int, T>* instances = get_instances();
  id = (id == 0 && !instances->empty()) ? instances->rbegin()->first : id;
  instances->erase(id);
}

template <typename T>
T* Session<T>::get(int id) {
  std::map<int, T>* instances = get_instances();
  if (id == 0)
    return (instances->empty()) ? NULL : &instances->rbegin()->second;
  typename std::map<int, T>::iterator instance = instances->find(id);
  if (instance == instances->end())
    mexErrMsgIdAndTxt("mex:instanceNotFound",
                      "Invalid id %d. Did you open?", id);
  return &instance->second;
}

template <typename T>
const std::map<int, T>& Session<T>::get_const_instances() {
  return *get_instances();
}

template <typename T>
std::map<int, T>* Session<T>::get_instances() {
  static std::map<int, T> instances;
  return &instances;
}

} // namespace mex

#endif // __MEX_SESSION_H__