
//ƽ�й�
struct DirLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	unused;		//��4D������������
};

//���Դ
struct PointLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	pos;		//��Դλ��
	float	range;		//��Դ���䷶Χ

	float3	att;		//��ǿ˥��ϵ��
	float	unused;		//"4D����"������
};

//�۹��
struct SpotLight
{
	float4	ambient;	//������
	float4	diffuse;	//�������
	float4	specular;	//�߹�

	float3	dir;		//����
	float	range;		//���䷶Χ

	float3	pos;		//λ��
	float	spot;		//�۹�ǿ��ϵ��

	float3	att;		//���ϵ��
	float	theta;		//���ɢ�Ƕ�
};

//����
struct Material
{
	float4	ambient;
	float4	diffuse;
	float4	specular;	//specular�е�4��Ԫ�ش�����ʵı���⻬�̶�
};

void  OrenNayarDirctionLight(  Material mat,//ֻ��iffuse���������lambertģ�ͣ��������ӽǲ�ͬ������Ӱ
				DirLight L,
				float3	position,//����λ��
				float3	normal,
				float3	toEye,//"����->��"����,
				out 	float4 ambient,
				out		float4 diffuse,
				out		float4 specular
				)
{
	//��ʼ��  
    ambient  = float4(0.f,0.f,0.f,0.f);
	diffuse  = float4(0.f,0.f,0.f,0.f);
	specular = float4(0.f,0.f,0.f,0.f);

	float roughness = 10.0f;
	float4 lightColor = L.diffuse + L.ambient + L.specular;
	const float PI = 3.1415926;

	float dotNL = dot(normal, L.dir);
	float dotNV = dot(normal, toEye);

	float angleVN = acos(dotNV);
	float angleLN = acos(dotNL);

	float alpha = max(angleVN, angleLN);
	float beta = min(angleVN, angleLN);
	float gamma = dot(toEye - normal *dot(toEye,normal),L.dir-normal*dot(L.dir,normal));
	float roughnessSquared = roughness*roughness;

	float A = 1.0 - 0.5*(roughnessSquared / (roughnessSquared + 0.57));
	float B = 0.45 * (roughnessSquared / (roughnessSquared + 0.09));
    float C = sin(alpha) * tan(beta);

	float L1 = max(0.0, dotNL)*(A + B * max(0.0, gamma)*C);
	diffuse = L.diffuse * L1;
	ambient = L.ambient * mat.ambient;
	specular = L.specular * mat.specular;

}


