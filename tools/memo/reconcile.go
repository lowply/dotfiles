package main

func reconcile(directory string, index *store) error {
	return index.inner.ReconcileDirectory(directory)
}
