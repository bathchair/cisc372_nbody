FLAGS= -DDEBUG
LIBS= -lm
ALWAYS_REBUILD=makefile

nbody_gpu: nbody_gpu.o compute_gpu.o
	nvcc $(FLAGS) $^ -o $@ $(LIBS)
compute_gpu.o: compute_gpu.cu compute_gpu.cuh config.h vector.h $(ALWAYS_REBUILD)
	nvcc $(FLAGS) -c $<
nbody_gpu.o: nbody_gpu.c compute_gpu.h planets.h config.h vector.h $(ALWAYS_REBUILD)
	gcc $(FLAGS) -c $<
nbody: nbody.o compute.o
	gcc $(FLAGS) $^ -o $@ $(LIBS)
nbody.o: nbody.c planets.h config.h vector.h $(ALWAYS_REBUILD)
	gcc $(FLAGS) -c $< 
compute.o: compute.c config.h vector.h $(ALWAYS_REBUILD)
	gcc $(FLAGS) -c $< 
clean:
	rm -f *.o nbody nbody_gpu 
