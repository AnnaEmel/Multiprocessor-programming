
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <iostream>
#include <fstream>
#include <chrono>

typedef unsigned int uint;

void GenInput(int size, int num_steps);

void Process_GPU( bool* field_in, bool* field_out, uint field_size, uint num_steps );
__global__ void ProcessCell_GPU( bool* field_in, bool* field_out, int field_size );

void Process_CPU( bool* field_in, bool* field_out, uint field_size, uint num_steps );
void ProcessCell_CPU( bool* field_in, bool* field_out, uint i, int field_size );

void WriteResults( bool* out, uint field_size, const std::string& name );

int main(int argc, char* argv[])
{
	GenInput(100, 500);

	std::ifstream f( "input.txt" );
	if( !f )
	{
		std::cout << "Cannot open 'input.txt'" << std::endl;
		return -1;
	}

	uint field_size = 0;
	f >> field_size;

	uint num_steps = 0;
	f >> num_steps;

	uint cells_count = field_size*field_size;

	bool* field_in = new bool[cells_count];

	for( uint i = 0; i < cells_count; ++i )
		f >> field_in[i];
	
	bool* field_out_gpu = new bool[cells_count];
	bool* field_out_cpu = new bool[cells_count];

	std::chrono::time_point<std::chrono::steady_clock> t;
	std::chrono::microseconds delta;

	std::cout << "Starting GPU simulation..." << std::endl;
	t = std::chrono::steady_clock::now();
	Process_GPU( field_in, field_out_gpu, field_size, num_steps );
	delta = std::chrono::duration_cast<std::chrono::microseconds>( std::chrono::steady_clock::now() - t );
	std::cout << "GPU time: " << delta.count() << " microseconds" << std::endl;

	std::cout << "----------------------------------------" << std::endl;

	std::cout << "Starting CPU single thread simulation..." << std::endl;
	t = std::chrono::steady_clock::now();
	Process_CPU( field_in, field_out_cpu, field_size, num_steps );
	delta = std::chrono::duration_cast<std::chrono::microseconds>( std::chrono::steady_clock::now() - t );
	std::cout << "CPU time: " << delta.count() << " microseconds" << std::endl;

	for( uint i = 0; i < cells_count; ++i )
		if( field_out_cpu[i] != field_out_gpu[i] )
		{
			std::cout << "Validation fail" << std::endl;
			return -1;
		}

	WriteResults( field_out_cpu, field_size, "result.txt" );

	delete[] field_in;
	delete[] field_out_gpu;
	delete[] field_out_cpu;

	return 0;
}

void GenInput(int size, int num_steps)
{
	std::ofstream f( "input.txt" );

	f << size << ' ' << num_steps << '\n';
	for( int i = 0; i < size; ++i )
	{
		for( int j = 0; j < size; ++j )
		{
			f << rand() % 2 << ' ';
		}
		f << '\n';
	}
}

void Process_GPU( bool* field_in, bool* field_out, uint field_size, uint num_steps )
{
	uint cells_count = field_size*field_size;
	size_t array_size = sizeof( bool ) * cells_count;

	bool* fields[2];

	cudaMalloc( (void**)( &fields[0] ), array_size );
	cudaMalloc( (void**)( &fields[1] ), array_size );

	cudaMemcpy( fields[0], field_in, array_size, cudaMemcpyHostToDevice );

	const int threads_per_block = 100;

	int in, out;

	for( uint i = 0; i < num_steps; ++i )
	{
		in = i % 2;
		out = ( i + 1 ) % 2;
		ProcessCell_GPU <<< cells_count / threads_per_block, threads_per_block >>> ( fields[in], fields[out], field_size );
		cudaMemcpy( fields[in], fields[out], array_size, cudaMemcpyDeviceToDevice );
	}

	cudaMemcpy( field_out, fields[in], array_size, cudaMemcpyDeviceToHost );

	cudaFree( fields[0] );
	cudaFree( fields[1] );
}

__global__ void ProcessCell_GPU( bool* field_in, bool* field_out, int field_size )
{
	uint i = blockIdx.x * blockDim.x + threadIdx.x;

	int x = i % field_size;
	int y = i / field_size;

	int neighbours_count = 0;

	for( int cx = x - 1; cx <= x + 1; ++cx )
		for( int cy = y - 1; cy <= y + 1; ++cy )
		{
			if( cx == x && cy == y )
				continue;

			int nx = cx;
			int ny = cy;

			if( nx < 0 )
				nx = field_size - 1;

			if( nx >= field_size )
				nx = 0;

			if( ny < 0 )
				ny = field_size - 1;

			if( ny >= field_size )
				ny = 0;

			neighbours_count += (int)field_in[nx + ny * field_size];
		}

	if( field_in[i] )
	{
		if( neighbours_count == 2 || neighbours_count == 3 )
			field_out[i] = true;
		else
			field_out[i] = false;
	}
	else
	{
		if( neighbours_count == 3 )
			field_out[i] = true;
		else
			field_out[i] = false;
	}
}

void Process_CPU( bool* field_in, bool* field_out, uint field_size, uint num_steps )
{
	uint cells_count = field_size*field_size;
	size_t array_size = sizeof( bool ) * cells_count;

	bool* fields[2];
	fields[0] = new bool[cells_count];
	fields[1] = new bool[cells_count];

	memcpy( fields[0], field_in, array_size );

	int in, out;

	for( uint i = 0; i < num_steps; ++i )
	{
		in = i % 2;
		out = ( i + 1 ) % 2;
		for( uint j = 0; j < cells_count; ++j )
			ProcessCell_CPU( fields[in], fields[out], j, field_size );

		memcpy( fields[in], fields[out], array_size );
	}

	memcpy( field_out, fields[out], array_size );

	delete[] fields[0];
	delete[] fields[1];
}

void ProcessCell_CPU( bool* field_in, bool* field_out, uint i, int field_size )
{
	int x = i % field_size;
	int y = i / field_size;

	int neighbours_count = 0;

	for( int cx = x - 1; cx <= x + 1; ++cx )
		for( int cy = y - 1; cy <= y + 1; ++cy )
		{
			if( cx == x && cy == y )
				continue;

			int nx = cx;
			int ny = cy;

			if( nx < 0 )
				nx = field_size - 1;

			if( nx >= field_size )
				nx = 0;

			if( ny < 0 )
				ny = field_size - 1;

			if( ny >= field_size )
				ny = 0;

			neighbours_count += (int)field_in[nx + ny * field_size];
		}

	if( field_in[i] )
	{
		if( neighbours_count == 2 || neighbours_count == 3 )
			field_out[i] = true;
		else
			field_out[i] = false;
	}
	else
	{
		if( neighbours_count == 3 )
			field_out[i] = true;
		else
			field_out[i] = false;
	}
}

void WriteResults( bool* out, uint field_size, const std::string& name )
{
	std::ofstream of( name );

	for( uint i = 0; i < field_size; ++i )
	{
		for( uint j = 0; j < field_size; ++j )
			of << out[i * field_size + j] << ' ';

		of << '\n';
	}
}